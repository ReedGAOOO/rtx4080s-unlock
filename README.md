# rtx4080s-unlock — Windows · RTX 4080 SUPER · 32GB Mod

**Windows-first Tensor Core unlock research for a 32GB-modded RTX 4080 SUPER (`10de:2702`).**

This project explores a narrowly defined configuration: **Windows + RTX 4080 SUPER + a 32GB VRAM modification**. Its contribution is the board-specific UEFI adaptation, checked automatic startup workflow, recovery controls and published validation evidence for that combination. It is an early exploration of this niche, building on the upstream unlock research.

**Novelty scope:** searches during preparation did not identify a publicly documented example matching all three characteristics. That is a limited search observation, not proof of being the first worldwide; earlier or unpublished work may exist. The underlying unlock technique is credited to its upstream authors.

**English** | [简体中文](README.zh-CN.md)

> **For learning, research and controlled experimentation.** This is not a supported driver, a production-ready installer, or a universal RTX 40-series unlock. Hardware access can cause hangs, black screens, GPU resets, data loss or boot failure; recovery is not guaranteed. Read the [disclaimer](DISCLAIMER.md) before building or adapting anything.

This repository publishes the source and validation record of a hardware-specific adaptation built on [TOTORONG/AD103_win_unlocker](https://huggingface.co/TOTORONG/AD103_win_unlocker) and [Zagitta/gpu-unlock](https://github.com/Zagitta/gpu-unlock). It does not claim discovery of the underlying exploit or a world first. See [attribution](THIRD_PARTY_NOTICES.md).

## What was demonstrated

* One **RTX 4080 SUPER**, PCI `10de:2702`, subsystem `10de:18cc`, AD103 A1, modified to **32GB** (32,760 MiB reported).
* Windows 11 Pro, NVIDIA **617.42**, VBIOS `95.03.44.40.74`; the original Windows driver and VBIOS were not replaced by this experiment.
* Pre-Windows UEFI execution, a checked firmware transaction, one PCIe FLR, display reconnection, and return to Windows.
* Automatic BootNext renewal **only after** a matching new success report and Windows CUDA correctness/throughput check.
* Secure Boot remained reported as enabled on the tested machine. This is a machine-specific observation, **not** a Microsoft signature or proof that other firmware accepts this EFI.

| Measurement | Observed result | Scope |
|---|---:|---|
| v0.6.2 Windows boot health, FP16 input / FP32 accumulate | **196.09 TFLOPS** median | 5 register-resident instruction samples; 270,336 output cells, zero mismatches |
| FP8 E4M3 / FP32 accumulate short probe | **387.71 TFLOPS** median | 256-iteration register-resident probe; 3 samples, zero mismatches |
| FP8 E5M2 / FP32 accumulate short probe | **387.71 TFLOPS** median | Same short protocol |

These are instruction-throughput microbenchmarks, **not model inference rates**. There is no matched same-card stock FP8 baseline in this release, so it does **not** claim a measured 2x FP8 improvement. The longer 10,000-iteration FP8 accumulation probe failed numerical validation; its cause is unresolved. See [evidence and limitations](docs/VALIDATION.md).

## Publication status

**Source release: `0.6.2-public.1`. Tested local deployment: `0.6.2`.**

Private disk, volume and GPU identifiers have been replaced with examples. The public build explicitly disables boot-partition matching, and the host script refuses installation/confirmation outside its read-only/test modes. No deployable EFI, board ROM, firmware image or signing key is distributed. This prevents the reference profile from silently becoming an installer for another machine.

The public reference build has not been executed on hardware. Its hash differs from the tested local EFI. Do not equate a successful compile or CPU simulation with hardware compatibility. Removing a guard does not establish compatibility.

## Start here

1. Read [DISCLAIMER.md](DISCLAIMER.md) and [known issues](docs/KNOWN-ISSUES.md).
2. Follow [BUILD.md](docs/BUILD.md) to compile and inspect the **non-deployable reference**.
3. Read [PORTING.md](docs/PORTING.md) for the evidence needed to adapt another machine/card.
4. Read [BOOT-LIFECYCLE.md](docs/BOOT-LIFECYCLE.md) before designing automatic startup or recovery.

There is deliberately no “download and run this EFI” shortcut. Even another 2702/32GB board can have a different ROM, subsystem, topology or firmware behavior.

## Repository layout

| Path | Purpose |
|---|---|
| `source/unlock/` | UEFI application, checked GPU transaction, hardware/profile guards and CPU test harness |
| `source/firmware-tools/` | Upstream GPL tools and pinned metadata for **local** firmware preparation |
| `host/` | Windows renewal/health implementation; public installation is blocked |
| `notifier/` | Existing login-only failure notification reference; not a runtime GPU-reset monitor |
| `benchmarks/` | FP16/TF32/INT4 and FP8 microbenchmark sources and runners |
| `evidence/` | Curated success gates, health results, historical tests and unresolved FP8 failure |
| `docs/` | Build, adaptation, lifecycle, recovery and validation notes |

## What this is not

* It is not a VBIOS flash or permanent silicon modification. The local deployment reapplies a volatile change before Windows starts.
* It does not add CUDA cores, memory bandwidth, professional-driver certification or vGPU entitlement.
* It does not establish support for arbitrary 4080 SUPER boards, other RTX 40 cards or another driver release.
* It does not establish long-term stability. WSL GPU workloads previously coincided with TDRs and a `0x20001 HYPERVISOR_ERROR`; resource pressure was observed, but unlock involvement has not been ruled out.

## Contributing

Useful contributions include reproducible **same-card** stock/unlocked measurements, complete failure-stage analysis, read-only compatibility captures and independent code review. Please state GPU/device/subsystem, VRAM, ROM hash, driver, OS, precision/accumulator, matrix sizes, clocks/power policy and numerical checks. Remove user names, GPU/disk UUIDs, keys and raw crash dumps before posting. Do not attach ROMs or proprietary firmware.

Report compatibility as “tested on this exact configuration,” not “all 4080 SUPER cards supported.” See [CONTRIBUTING.md](CONTRIBUTING.md).

## License

GPL-2.0-only for the GPL-derived code and this project's new contributions, subject to retained third-party notices. See [LICENSE](LICENSE), [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md) and [LICENSES/](LICENSES/). Firmware is not relicensed by this repository. The educational/research description does not remove rights granted by the applicable open-source licenses.
