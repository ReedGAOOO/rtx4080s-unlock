# Contributing

Start with a small, reviewable change and state which exact configuration it addresses. Preserve upstream attribution, license notices, source guards and failure records.

For compatibility reports include GPU model, PCI/subsystem IDs, VRAM, VBIOS version/hash, driver/OS, display topology, boot path, last successful stage and sanitized error text. Keep identifiers, credentials, keys, ROMs, proprietary firmware and raw memory dumps local; submit sanitized evidence.

For performance reports include same-card stock/unlocked controls, kernel source and hash, input/accumulator precision, matrix shape or instruction geometry, sparsity, warmups/repetitions, power/clocks, timing method and numerical checks. Include both successful and failed runs and distinguish measured baselines from theoretical peaks.

Run `python tools/check_publication.py` and the relevant CPU/host tests. Any hardware run is separate and requires the machine owner's informed authorization. Public CI covers source and CPU-only checks.

Contributions are provided under the applicable repository license. Retain the rights granted by inherited GPL code.
