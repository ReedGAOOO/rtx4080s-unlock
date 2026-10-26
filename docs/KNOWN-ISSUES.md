# Known issues

| Issue | Status |
|---|---|
| Support beyond one 2702/18cc 32GB board | Not established |
| Long-term WSL/GPU stability | Unproven; historical TDR/hypervisor crash not fully explained |
| FP8 long accumulation numerical discrepancy | Open; short test passing does not resolve it |
| Same-card stock/unlocked FP8 comparison | Missing |
| Fast Startup retaining boot identity and stale FAT view | Observed; disabled on the tested host with owner approval |
| GPU reset after login invalidating unlock state | Login-only notifier does not detect this |
| Failure popup delivery | Logic inspected, end-to-end delivery not independently proven |
| Generic Secure Boot acceptance | Not provided; no Microsoft signature or portable trust chain |
| Arbitrary initial SS0/SS1 values | Refused; only reviewed local paths accepted |
| FBPA readback not changing | Known nonfatal observation in inherited transaction; no claim that all four intended PLM writes independently succeeded |
| Public profile/build | Sanitized and hardware-disabled; not a ready-to-run deployment |
| Firmware redistribution | No firmware/ROM/payload binaries distributed |

Issue reports should include evidence, a bounded reproduction and the relevant validation result.
