**English** | [简体中文](README.zh-CN.md)

# rtx4080s-unlock

**Windows UEFI Tensor Core unlock for a 32GB-modded RTX 4080 SUPER, with automatic startup and benchmarks.**

## Measured results: 4080 SUPER vs 4090 vs 5090

**2026-10-26 · actual measurements · median TFLOPS.** The 4080 SUPER and 4090 were unlocked; the 5090 was stock.

### Instruction throughput

| Test (input / accumulate) | 4080 SUPER 32GB · unlocked | 4090 24GB · unlocked | 5090 32GB · stock |
|---|---:|---:|---:|
| FP16 / FP16 | 204.80 | 327.50 | 449.10 |
| FP16 / FP32 | 205.00 | 327.30 | 224.80 |
| BF16 / FP32 | 204.90 | 327.00 | 224.50 |
| FP8 E4M3 | 408.40 | 651.90 | 449.20 |
| FP32 FFMA | 50.50 | 78.00 | 109.10 |

### cuBLAS matrix multiplication — 8192 × 8192 × 8192

| Test (input / accumulate) | 4080 SUPER 32GB · unlocked | 4090 24GB · unlocked | 5090 32GB · stock |
|---|---:|---:|---:|
| FP16/FP32 GEMM 8192³ | 190.49 | 195.72 | 236.12 |
| BF16/FP32 GEMM 8192³ | 190.15 | 205.05 | 234.49 |

**Test conditions:** 4080 SUPER: Windows/WSL2, 320W cap, driver 617.42; 4090: Linux, 550W cap, driver 595.99.02; 5090: Linux, 575W cap, driver 570.211.01. The two Ada cards used identical binaries/cuBLAS 12.4.5.8. The 5090 used native `sm_120`, CUDA 12.8.93 and cuBLAS 12.8.4.1: workload and launch parameters match, but the software stack differs.

Each card passed 169,869,312 FP16/BF16 GEMM output checks plus six seeded cases, with zero mismatches. FP8 instruction throughput is reported separately; its long-accumulation validation issue is tracked in [known issues](docs/KNOWN-ISSUES.md).

At 8192³, this 4080 SUPER reached about **97% / 93%** of the unlocked 4090's FP16/BF16 GEMM throughput, despite about **63%** of its FP32-accumulating Tensor instruction throughput. These results describe this workload; the linked report gives the full comparison conditions. [Full tables, samples and methodology](docs/COMPARISON.md).

## Project contribution

Focused on **Windows + RTX 4080 SUPER + a 32GB VRAM modification**, this project implements a board-specific UEFI port, automatic startup unlock, result archival and login checks, with published source, tests and porting notes. It is an early exploration of this configuration: preparation-time searches found no matching public example, and the community may supply earlier work.

* **Windows boot path:** UEFI execution → PCIe FLR → display recovery → Windows.
* **Automatic startup:** renew BootNext after a new report and CUDA check pass; retain failure records.
* **Tested configuration:** `10de:2702` / `10de:18cc`, AD103 A1, 32GB mod, Windows 11 Pro, driver 617.42, VBIOS `95.03.44.40.74`.
* **Validation:** 113 CPU simulation scenarios, 37 host policy tests, hardware records and three-GPU benchmarks.

## Getting started

Source version **0.6.2-public.1** derives from the tested local deployment **0.6.2**. Published profiles use placeholder identities and the default build disables hardware execution. Follow the porting guide to produce a target-specific configuration before deployment. Prepare firmware and ROM inputs locally under their upstream licenses.

1. [Build and test](docs/BUILD.md)
2. [Adapt to your board](docs/PORTING.md)
3. [Automatic startup, notifications and recovery](docs/BOOT-LIFECYCLE.md)
4. [Full three-GPU comparison](docs/COMPARISON.md) · [Historical validation](docs/VALIDATION.md) · [Known issues](docs/KNOWN-ISSUES.md)

## Layout

| Path | Contents |
|---|---|
| `source/unlock/` | UEFI application, GPU transaction, target profile and tests |
| `source/firmware-tools/` | Upstream firmware preparation tools and pinned metadata |
| `host/`, `notifier/` | Windows renewal, health checks and login notification |
| `benchmarks/`, `evidence/` | Microbenchmark source, measurements and samples |
| `docs/` | Build, porting, boot and validation documentation |

## Upstream and license

Built on the unlock research in [TOTORONG/AD103_win_unlocker](https://huggingface.co/TOTORONG/AD103_win_unlocker) and [Zagitta/gpu-unlock](https://github.com/Zagitta/gpu-unlock). This project's contribution is adaptation and deployment for the Windows board configuration above. See [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md) for full attribution.

**For learning and research.** Licensed under [GPL-2.0](LICENSE), with retained third-party licenses; the purpose statement adds no GPL usage restriction. Hardware risks and warranty terms are collected in the [disclaimer](DISCLAIMER.md).

Contributions of porting records, matched before/after results, reproducible issues and code improvements are welcome. See [CONTRIBUTING.md](CONTRIBUTING.md).
