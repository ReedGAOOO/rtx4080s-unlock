# Contributing

Start with a small, reviewable change and state which exact configuration it addresses. Preserve upstream attribution, license notices, source guards and failure records.

For compatibility reports include GPU model, PCI/subsystem IDs, VRAM, VBIOS version/hash, driver/OS, display topology, boot path, last successful stage and sanitized error text. Do not post GPU/disk UUIDs, private paths, credentials, signing/recovery keys, raw ROMs, proprietary firmware, complete memory dumps or unreviewed screenshots.

For performance reports include same-card stock/unlocked controls, kernel source and hash, input/accumulator precision, matrix shape or instruction geometry, sparsity, warmups/repetitions, power/clocks, timing method and numerical checks. A single peak or a vendor AI TOPS figure is not a matched baseline. Report failures as well as successes.

Run `python tools/check_publication.py` and the relevant CPU/host tests. Any hardware run is separate and requires the machine owner's informed authorization. Public CI must not execute EFI, manipulate firmware variables, run GPU workloads, or obtain proprietary payloads.

Contributions are provided under the applicable repository license. Do not introduce additional usage restrictions on inherited GPL code.
