using System;
using System.Runtime.InteropServices;
public sealed class RtxProbeResult {public double MedianTflops;public double[] Tflops;public int Cells;public int Mismatches;}
public static class RtxCudaProbe {
 [DllImport("nvcuda.dll")] static extern int cuInit(uint f);
 [DllImport("nvcuda.dll")] static extern int cuDeviceGetCount(out int n);
 [DllImport("nvcuda.dll")] static extern int cuCtxCreate_v2(out IntPtr c,uint flags,int dev);
 [DllImport("nvcuda.dll")] static extern int cuCtxDestroy_v2(IntPtr c);
 [DllImport("nvcuda.dll",CharSet=CharSet.Ansi)] static extern int cuModuleLoad(out IntPtr module,string filename);
 [DllImport("nvcuda.dll")] static extern int cuModuleUnload(IntPtr m);
 [DllImport("nvcuda.dll",CharSet=CharSet.Ansi)] static extern int cuModuleGetFunction(out IntPtr f,IntPtr m,string name);
 [DllImport("nvcuda.dll")] static extern int cuMemAlloc_v2(out ulong ptr,UIntPtr n);
 [DllImport("nvcuda.dll")] static extern int cuMemFree_v2(ulong ptr);
 [DllImport("nvcuda.dll")] static extern int cuMemcpyDtoH_v2([Out]float[] data,ulong ptr,UIntPtr n);
 [DllImport("nvcuda.dll")] static extern int cuLaunchKernel(IntPtr f,uint gx,uint gy,uint gz,uint bx,uint by,uint bz,uint shared,IntPtr stream,IntPtr parameters,IntPtr extra);
 [DllImport("nvcuda.dll")] static extern int cuCtxSynchronize();
 [DllImport("nvcuda.dll")] static extern int cuEventCreate(out IntPtr e,uint flags);
 [DllImport("nvcuda.dll")] static extern int cuEventDestroy_v2(IntPtr e);
 [DllImport("nvcuda.dll")] static extern int cuEventRecord(IntPtr e,IntPtr stream);
 [DllImport("nvcuda.dll")] static extern int cuEventSynchronize(IntPtr e);
 [DllImport("nvcuda.dll")] static extern int cuEventElapsedTime(out float ms,IntPtr start,IntPtr end);
 static void Check(int n,string op){if(n!=0)throw new Exception(op+": CUDA error "+n);}
 public static RtxProbeResult Run(string cubin) {
  IntPtr context=IntPtr.Zero,module=IntPtr.Zero,start=IntPtr.Zero,end=IntPtr.Zero,parameters=IntPtr.Zero,iters=IntPtr.Zero,ptr=IntPtr.Zero;ulong memory=0;
  try {
   Check(cuInit(0),"init");int count;Check(cuDeviceGetCount(out count),"count");if(count!=1)throw new Exception("Exactly one CUDA device required");
   Check(cuCtxCreate_v2(out context,0,0),"context");Check(cuModuleLoad(out module,cubin),"module");
   IntPtr fn;Check(cuModuleGetFunction(out fn,module,"bench_f16_f32"),"function");
   const int cells=1056*256;Check(cuMemAlloc_v2(out memory,(UIntPtr)(cells*4)),"allocate");
   iters=Marshal.AllocHGlobal(8);ptr=Marshal.AllocHGlobal(8);parameters=Marshal.AllocHGlobal(16);
   Marshal.WriteInt64(iters,20000);Marshal.WriteInt64(ptr,unchecked((long)memory));Marshal.WriteIntPtr(parameters,0,iters);Marshal.WriteIntPtr(parameters,8,ptr);
   Action launch=()=>Check(cuLaunchKernel(fn,1056,1,1,256,1,1,0,IntPtr.Zero,parameters,IntPtr.Zero),"launch");
   launch();Check(cuCtxSynchronize(),"warmup");
   Check(cuEventCreate(out start,0),"start event");Check(cuEventCreate(out end,0),"end event");
   double[] rates=new double[5];
   for(int i=0;i<rates.Length;i++) {
    Check(cuEventRecord(start,IntPtr.Zero),"start");launch();Check(cuEventRecord(end,IntPtr.Zero),"end");Check(cuEventSynchronize(end),"wait");
    float ms;Check(cuEventElapsedTime(out ms,start,end),"time");if(ms<=0)throw new Exception("Invalid duration");
    rates[i]=(1056.0*8*20000*8*16*8*16*2)/(ms*1e9);
   }
   float[] outputs=new float[cells];Check(cuMemcpyDtoH_v2(outputs,memory,(UIntPtr)(cells*4)),"read output");
   int bad=0;foreach(float x in outputs)if(x!=10240000.0f)bad++;
   double[] sorted=(double[])rates.Clone();Array.Sort(sorted);
   return new RtxProbeResult{MedianTflops=sorted[2],Tflops=rates,Cells=cells,Mismatches=bad};
  } finally {
   if(start!=IntPtr.Zero)cuEventDestroy_v2(start);if(end!=IntPtr.Zero)cuEventDestroy_v2(end);
   if(parameters!=IntPtr.Zero)Marshal.FreeHGlobal(parameters);if(iters!=IntPtr.Zero)Marshal.FreeHGlobal(iters);if(ptr!=IntPtr.Zero)Marshal.FreeHGlobal(ptr);
   if(memory!=0)cuMemFree_v2(memory);if(module!=IntPtr.Zero)cuModuleUnload(module);if(context!=IntPtr.Zero)cuCtxDestroy_v2(context);
  }
 }
}
