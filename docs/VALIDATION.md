# Evidence and limits

Dates/times in narrative refer to Asia/Singapore. Some JSON boot stamps are UTC. Run names are reused after successful archival; the archive number and report hash distinguish attempts.

## Successful v0.6.2 boot

On 2026-10-26 at 03:20:48 local time, Windows started through the local experimental path. At 03:21:33 the health task recorded:

* FP16 input / FP32 accumulation median **196.08835983933338 TFLOPS** across five instruction samples.
* **270,336** checked output cells, **0** mismatches.
* Successful transaction containment, FLR, GOP reconnection and Windows handoff.
* SS0=`0x88888888`, SS1=`0x00000008` after FLR and again after GOP.
* Automatic renewal recorded as `confirmed-next-boot-queued`.

The local full-report SHA-256 is `5a9ea79eed359f2bad3a609328e8dc83030bc034973d64f95ec56985325ad245`. `evidence/v062-success-excerpt.txt` is a **curated subset**, not the full file; its hash will not match that full-report hash. The original report remains private. `evidence/v062-health.json` contains the matching health record.

## FP8 short probe

`benchmarks/fp8_short.cu` adapts the upstream register-resident probe to `mma.sync.aligned.m16n8k32` with E4M3/E5M2 inputs and FP32 accumulation. Inputs are all ones, eight accumulator chains, 1,056 blocks, 256 threads per block. This is not a cuBLAS/CUTLASS application GEMM.

The successful short run used **256 iterations**, one warmup and three timed launches per mode. E4M3 and E5M2 each had median **387.70876038338173 TFLOPS** with every one of 270,336 summed outputs matching the reference. The FP16 control median was **192.2389304190177 TFLOPS**. Recorded CUDA context/test time was about 0.173 seconds, excluding build and initial GPU identity query. Single-kernel times were around 0.366 ms, so these are short-run estimates.

The first 10,000-iteration E4M3 run **failed**: every checked output differed (expected 10,240,000, observed first/last 524,288). The runner stopped before completing that run. This may involve long-accumulation behavior or a benchmark issue; the cause has not been established. The short run does not resolve that discrepancy. It must not be omitted from performance/precision claims.

There is no matched stock FP8 measurement for this card in this release. A comparison to an architecture-derived theoretical rate is not a measured before/after ratio. No claim of doubled application speed, validated training accuracy or complete FP8 coverage is made.

## CPU simulation and host tests

The private local v0.6.2 application passed **113** mock application/core scenarios under ASan/UBSan. Inputs included a privately retained 256-byte PCI configuration, 20 initial registers, 859 KiB PROM and hash-pinned firmware. Reads/writes, DMA, firmware success/failure, reset and display ownership were simulated. Those tests cannot establish actual firmware acceptance or physical recovery.

The private Windows host passed **37** policy/file/UTF-8 tests without calling firmware APIs or CUDA. Historical reports are included. Public rebuild/test results are recorded separately in `evidence/publication-checks.json` after sanitization; do not confuse those with a new hardware test.

## Unresolved stability observations

Earlier WSL GPU work coincided with TDR events and `0x20001 HYPERVISOR_ERROR`. VRAM/system-commit pressure and workload batching problems were observed, and responsiveness returned after work stopped. This does **not** establish a unique cause or rule out the unlock, driver, memory modification or WSL. No extended stability or multi-card qualification has been completed.

The original local reference uses 610.43.03-derived firmware inputs with Windows driver 617.42. This exact experiment is not evidence that arbitrary firmware/driver combinations are compatible.
