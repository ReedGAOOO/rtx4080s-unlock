# Porting guide

The demonstrated card is `10de:2702`, subsystem `10de:18cc`, AD103 A1, VBIOS `95.03.44.40.74`, modified to 32GB. The profile also pins PCI location, BAR mapping, display path, ROM contents, firmware assets and bounded initial registers. Collect these values for each target board.

## Public versus tested profile

`source/unlock/target_profile.h`, `prom_profile.h` and the initial-state checks record the reference board's technical observations. `fixed_source.h` and host identity fields use synthetic disk/volume/GPU identifiers. `source/build_candidate.py` defines `GU_PUBLIC_REFERENCE_BUILD`, which always rejects source partition matching. The host installer is also blocked outside PolicyOnly/Status.

For a hardware-enabled port, replace target-specific assumptions with verified observations, review the changes and validate the resulting build on the target.

## Evidence required before a hardware-enabled build

1. Record GPU PCI/subsystem, chip, VRAM, driver, VBIOS and complete display topology. Keep private identifiers local.
2. Export the owner's original VBIOS and retain its hash locally. Match PROM parsing, firmware signature slots and asset hashes; retain the ROM locally.
3. Inspect PCI command/BARs, read-only preflight observations and required bounded registers using an audited collector. Keep reads within the reviewed MMIO ranges.
4. Verify the selected test partition's disk identity, format, start/length, marker and device path. Use the target machine’s actual geometry.
5. Replay the complete application with local fixtures and fault injection. Confirm every rejection, DMA containment, one-attempt lock, FLR, display-recovery and Windows-handoff path.
6. Review all source changes and expected write ranges with the machine owner. Obtain explicit authorization for the exact hardware trial and recovery procedure. List any required firmware or system-setting changes separately.
7. Run a single controlled trial. Confirm a valid post-GOP report and a fresh Windows correctness/throughput check.
8. Establish matched stock/unlocked tests with the same clocks, power policy, software, precision, shape and numerical validation. Validate stability separately before automating.

For another RTX 40-series GPU, firmware architecture/signature selection, chip resources, ROM layout, display ownership and reset behavior may change. Validate these components for the new target.

## v0.6.2 admission change

The earlier failure was SS1 at `0x823820`: a pinned expected value of `3` rejected an observed `0` while SS0 was also `0`. v0.6.2 keeps the original inactive SS0 / SS1=3 path and additionally accepts the **specific stable pair 0/0** on this local profile. Both selectors must remain stable across checks, and the other 18 pinned register checks remain.

The origin of the 0/0 initial state remains open. Final selectors are checked after FLR and GOP reconnection; additional initial states need evidence and regression cases.

## AI-assisted work

Inventory the target and read the validation and lifecycle documents. Prepare the configuration, tests and recovery artifacts, then obtain owner approval for each hardware trial or critical setting change. Diagnose retained failure records before scheduling another attempt.
