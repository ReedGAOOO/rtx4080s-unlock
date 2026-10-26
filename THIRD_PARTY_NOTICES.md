# Attribution and distribution scope

This is an experimental adaptation and validation project by ReedGAOOO, not the original discovery of the unlock mechanism and not a world-first claim.

* **TOTORONG/AD103_win_unlocker**, revision `51df9c17ec89eb8486df52cc9079dde4bd1f9974`: UEFI port, AD102-shaped SEC2 payload generation, Windows handoff and checked transaction foundation. https://huggingface.co/TOTORONG/AD103_win_unlocker
* **Zagitta/gpu-unlock**, upstream revision identified by the port as `0ebdb1c6308b6a2072be5bf04513472942541956`: core unlock/preparation/VBIOS/layout/diagnostic code. https://github.com/Zagitta/gpu-unlock
* **JustAResearcher/gpu-unlock-ada**, benchmark source snapshot `4e7fefcc4923f9e083d5324dc75a7d2f906af77f`: register-resident MMA probes and driver runner. https://github.com/JustAResearcher/gpu-unlock-ada
* **WildFlash1st/cmp90hx-unlock**, `76940ae583281daa2b883518a2e89b56c11d3a46`: V67 signature references retained by the upstream firmware-generation tools. https://github.com/WildFlash1st/cmp90hx-unlock
* **TianoCore EDK2**, headers pinned to `c1415771ac592ad8509351c46cd3cda4f38d7d52`: BSD-2-Clause-Patent. Headers are fetched separately. https://github.com/tianocore/edk2
* Retained NVIDIA MIT, CMP40HX MIT, EDK2 and driver notices are in `LICENSES/`. Original per-file notices remain applicable.

GPL-derived application, modifications, tests and benchmark code are distributed under GPL-2.0-only. Newly written project documentation is offered under the same license. This publication does not reproduce the upstream CC BY-NC narrative guides; read their separate terms at https://huggingface.co/TOTORONG/AD103_win_unlocker/blob/main/LICENSE-POLICY.md .

NVIDIA firmware, extracted/generated payload images, board ROMs, signing keys and ready-to-run EFI binaries are **not included**. The GPL license on tools does not relicense firmware inputs or outputs. Review the input terms before obtaining them locally. Upstream firmware provenance: https://huggingface.co/TOTORONG/AD103_win_unlocker/blob/main/source/firmware-tools/NOTICE.md .

## Changes in this publication

The local 2702/32GB adaptation added identity and PROM checks, bounded initial-state validation, SS0/SS1 stability checks, durable single-attempt state, automatic boot renewal and Windows health validation. v0.6.2 additionally admits the observed stable SS0=0/SS1=0 pair. It does not accept arbitrary selectors or prove that zero state is universally safe.

Publication changes replace private disk/volume/GPU identifiers with synthetic examples, disable reference EFI partition matching, block host installation outside PolicyOnly/Status, make dependency paths explicit, and add English/Chinese documentation. These changes are not a new hardware-tested EFI release. The installed private-profile EFI was not altered by publication.
