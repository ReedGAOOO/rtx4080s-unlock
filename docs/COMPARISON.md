# Three-GPU comparison / 三卡实测对比

2026-10-26 (Asia/Singapore). These are previously collected measurements; publishing this report did not rerun GPU tests or change any machine.

## Configuration

| GPU | State | Platform | Driver | Power cap | cuBLAS |
|---|---|---|---|---:|---|
| RTX 4080 SUPER 32GB mod | unlocked | Windows / WSL2 | 617.42 | 320W | 12.4.5.8 |
| RTX 4090 24GB | unlocked | Linux | 595.99.02 | 550W | 12.4.5.8 |
| RTX 5090 32GB | stock | Linux | 570.211.01 | 575W | 12.8.4.1 |

Power values are configured caps, not measured consumption. These are different machines/platforms and no fixed-clock policy was established. The 5090 is **not unlocked**, and this repository does not establish 5090 unlock support.

## Instruction throughput

Median of 15 samples (three rounds of five), following a two-repeat warmup; 20,000 inner iterations. Floating-point rows are TFLOPS; INT8 and DP4A rows are TOPS. These are the existing WMMA/PTX workloads, not a Blackwell architecture-optimized peak benchmark.

| Test (input / accumulate) | 4080 SUPER 32GB · unlocked | 4090 24GB · unlocked | 5090 32GB · stock |
|---|---:|---:|---:|
| FP16 / FP16 | 204.80 | 327.50 | 449.10 |
| FP16 / FP32 | 205.00 | 327.30 | 224.80 |
| BF16 / FP32 | 204.90 | 327.00 | 224.50 |
| INT8 / INT32 | 409.60 | 654.30 | 449.10 |
| FP8 E4M3 | 408.40 | 651.90 | 449.20 |
| DP4A | 99.20 | 162.40 | 223.20 |
| FP32 FFMA | 50.50 | 78.00 | 109.10 |

## cuBLAS GEMM

Square matrices, FP32 accumulation; 10 warmups, then five timed groups of 20 launches, reporting median TFLOPS. All six sizes/modes are included, including reversals in ranking.

| Test (input / accumulate) | 4080 SUPER 32GB · unlocked | 4090 24GB · unlocked | 5090 32GB · stock |
|---|---:|---:|---:|
| FP16/FP32 GEMM 1024³ | 107.01 | 133.15 | 129.75 |
| BF16/FP32 GEMM 1024³ | 106.73 | 160.09 | 102.57 |
| FP16/FP32 GEMM 4096³ | 171.82 | 195.82 | 223.57 |
| BF16/FP32 GEMM 4096³ | 190.43 | 159.67 | 185.07 |
| FP16/FP32 GEMM 8192³ | 190.49 | 195.72 | 236.12 |
| BF16/FP32 GEMM 8192³ | 190.15 | 205.05 | 234.49 |

## Validation and comparability

* Per GPU: 169,869,312 FP16/BF16 GEMM output checks, six seeded numerical cases, zero mismatches. These are bounded arithmetic checks, not training accuracy or long-term stability tests.
* The FP8 row is a throughput measurement. The seeded validator and GEMM checks cover FP16/BF16, not FP8. They do not resolve the earlier custom FP8 long-accumulation failure described in [VALIDATION.md](VALIDATION.md).
* 4080 SUPER and 4090 used identical executable and cuBLAS binary hashes. The 5090 used matching source workloads/launch parameters but native `sm_120`, CUDA 12.8.93 and cuBLAS 12.8.4.1. Its validator only broadened architecture admission; arithmetic checks were unchanged.
* Driver, OS, power cap, architecture and library differences prevent isolating the effect of hardware or unlock from this cross-card table. No broad claim that an unlocked 4090 beats a 5090 is supported. No FP8 GEMM or model inference result is present.
* The earlier 196.09 TFLOPS boot check and 387.71 TFLOPS short FP8 probe use different programs/protocols from this comparison. They remain separately documented and must not be combined into before/after ratios.

## Audit data

[Sanitized data and all samples](../evidence/three-gpu-comparison.json) include 15 instruction samples per mode/card, all GEMM timing groups, seeded validator lines, source/bundle hashes and the original private report hash. GPU UUIDs, host names, private paths and unrelated service configuration are omitted. The original report is not distributed; its hash is provenance, not a hash of this curated export. All displayed medians were recomputed from archived samples and GEMM timings before publication.

## 中文说明

4080 SUPER 与 4090 均为解锁状态，5090 为原厂状态；本仓库没有实现或验证 5090 解锁。两张 Ada 卡使用相同二进制及 cuBLAS，5090 的原生架构编译与库版本不同，因此这不是严格控制全部变量的硬件对比。功耗数字是上限，不是实测耗电。

前页重点展示指令吞吐和 8192³ GEMM；这里保留全部矩阵尺寸，包含排名反转的结果。FP16/BF16 数值校验通过不等于 FP8 正确性或长期稳定性通过，也不能用本表证明所有模型都达到某个提升比例。早先开机检查与 FP8 短测采用不同程序，不能混为同一套测试。
