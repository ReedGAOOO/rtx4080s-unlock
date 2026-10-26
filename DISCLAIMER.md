# Disclaimer

**English** | [简体中文](DISCLAIMER.zh-CN.md)

## Educational and research purpose

This project is published for learning, research, code review and controlled experimentation. It is an independent, hardware-specific experiment, not an NVIDIA/MSI/Microsoft-approved product, supported driver, consumer installation service or production-readiness claim. No affiliation or endorsement is implied.

## Hardware and data risks

The hardware-enabled implementation performs privileged pre-OS GPU operations, including firmware payload execution, DMA, register writes, device-driver release/reconnection and PCIe Function Level Reset. Incorrect assumptions or unexpected hardware states can cause black screens, hangs, incorrect computation, GPU unavailability, data loss or an unbootable system. Power cycling, restoring files or selecting Windows Boot Manager may not recover every failure. The absence of VBIOS flashing does not make the procedure risk-free.

One board's results do not establish another board's compatibility. PCI ID, product name and VRAM capacity alone are insufficient. Secure Boot enabled on the author's machine does not establish generic trust, signing or safety. Never delete failed-attempt records or remove checks simply to force execution.

Long-term stability is unproven. Prior GPU timeouts and a hypervisor crash are documented; causality is unresolved. A short FP8 numerical test passed, while a longer accumulation test did not. Do not rely on these results for safety-critical or correctness-critical decisions without independent validation.

## Responsibility and no warranty

Anyone adapting or executing hardware-enabled code must understand and independently assess the target configuration, preserve necessary backups and recovery options, and obtain the machine owner's informed authorization. This repository does not authorize changes to third-party systems or redistribution of third-party firmware.

To the extent permitted by applicable law, the software and documentation are provided **AS IS**, without express or implied warranties, including merchantability, fitness for a particular purpose, compatibility, accuracy, performance or successful recovery. Liability is limited as provided by the applicable license, including GPL-2.0 sections 11 and 12. Nothing here excludes rights or liabilities that cannot lawfully be excluded.

## License takes precedence

The learning/research description is a statement of intended use, not an additional field-of-use or noncommercial restriction on GPL-covered code. Retained third-party licenses continue to apply. Proprietary NVIDIA firmware and board ROMs are not licensed under this repository's GPL declaration. See [LICENSE](LICENSE) and [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).
