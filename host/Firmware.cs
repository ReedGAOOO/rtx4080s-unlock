using System;
using System.IO;
using System.Text;
using System.ComponentModel;
using System.Runtime.InteropServices;
using System.Text.RegularExpressions;
public static class RtxFirmware {
 const string Global="{8BE4DF61-93CA-11D2-AA0D-00E098032B8C}";
 [StructLayout(LayoutKind.Sequential)] struct Luid {public uint Low; public int High;}
 [StructLayout(LayoutKind.Sequential)] struct TokenPrivileges {public uint Count;public Luid Luid;public uint Attributes;}
 [DllImport("kernel32.dll")] static extern IntPtr GetCurrentProcess();
 [DllImport("kernel32.dll")] static extern bool CloseHandle(IntPtr h);
 [DllImport("advapi32.dll",SetLastError=true)] static extern bool OpenProcessToken(IntPtr p,uint access,out IntPtr token);
 [DllImport("advapi32.dll",CharSet=CharSet.Unicode,SetLastError=true)] static extern bool LookupPrivilegeValue(string system,string name,out Luid luid);
 [DllImport("advapi32.dll",SetLastError=true)] static extern bool AdjustTokenPrivileges(IntPtr token,bool disable,ref TokenPrivileges state,uint size,IntPtr prev,IntPtr returned);
 [DllImport("kernel32.dll",CharSet=CharSet.Unicode,SetLastError=true)] static extern uint GetFirmwareEnvironmentVariableEx(string name,string guid,byte[] data,uint bytes,out uint attributes);
 [DllImport("kernel32.dll",CharSet=CharSet.Unicode,SetLastError=true)] static extern bool SetFirmwareEnvironmentVariableEx(string name,string guid,byte[] data,uint bytes,uint attributes);
 public static void EnablePrivilege() {
  IntPtr token;
  if(!OpenProcessToken(GetCurrentProcess(),0x28,out token))throw new Win32Exception();
  try {Luid id;if(!LookupPrivilegeValue(null,"SeSystemEnvironmentPrivilege",out id))throw new Win32Exception();
   TokenPrivileges state=new TokenPrivileges{Count=1,Luid=id,Attributes=2};
   if(!AdjustTokenPrivileges(token,false,ref state,0,IntPtr.Zero,IntPtr.Zero)||Marshal.GetLastWin32Error()!=0)throw new Win32Exception();
  } finally {CloseHandle(token);}
 }
 public static byte[] Read(string name) {
  if(!Regex.IsMatch(name,"^(Boot[0-9A-F]{4}|BootCurrent|BootNext|BootOrder|SecureBoot|SetupMode)$"))throw new ArgumentException("Variable not allowlisted");
  byte[] data=new byte[65536];uint attributes;uint n=GetFirmwareEnvironmentVariableEx(name,Global,data,(uint)data.Length,out attributes);
  if(n==0){int e=Marshal.GetLastWin32Error();if(e==203)return null;throw new Win32Exception(e);}
  Array.Resize(ref data,(int)n);return data;
 }
 // Intentionally no method that can write BootOrder, Secure Boot or key databases.
 public static void Write(string name,byte[] data) {
  if(!Regex.IsMatch(name,"^(Boot[0-9A-F]{4}|BootNext)$"))throw new ArgumentException("Write outside Boot option/BootNext refused");
  // Get-SecureBootUEFI may disable this process privilege after its read.
  // Acquire it at the operation boundary, never assume earlier acquisition persists.
  EnablePrivilege();
  uint size=data==null?0:(uint)data.Length;
  if(!SetFirmwareEnvironmentVariableEx(name,Global,data,size,size==0?0u:7u))throw new Win32Exception();
  byte[] actual=Read(name);
  if(!Equal(actual,data))throw new IOException("Firmware readback mismatch: "+name);
 }
 public static bool Equal(byte[] a,byte[] b) {
  if(a==null||b==null)return a==b;if(a.Length!=b.Length)return false;
  for(int i=0;i<a.Length;i++)if(a[i]!=b[i])return false;return true;
 }
 public static byte[] LoadOption() {
  const string path="\\RTX-AUTO60\\RTXAUTO.EFI";
  byte[] file=Encoding.Unicode.GetBytes(path+"\0");
  using(var stream=new MemoryStream())using(var w=new BinaryWriter(stream)) {
   w.Write((uint)1);w.Write((ushort)(42+4+file.Length+4));
   w.Write(Encoding.Unicode.GetBytes("RTX 4080 SUPER Auto v0.6.0\0"));
   w.Write((byte)4);w.Write((byte)1);w.Write((ushort)42);w.Write((uint)2);
   w.Write((ulong)2048);w.Write((ulong)1048576);
   w.Write((uint)0xf00dbaad);w.Write(new byte[12]);w.Write((byte)1);w.Write((byte)1);
   w.Write((byte)4);w.Write((byte)4);w.Write((ushort)(4+file.Length));w.Write(file);
   w.Write((byte)0x7f);w.Write((byte)0xff);w.Write((ushort)4);
   return stream.ToArray();
  }
 }
}
