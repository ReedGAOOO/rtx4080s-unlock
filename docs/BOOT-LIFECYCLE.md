# Boot lifecycle, confirmation and recovery

## Observed local sequence

1. A separately owned firmware boot option points to the reviewed EFI on the test partition. The Windows BootOrder is preserved.
2. `BootNext` schedules **one** attempt. The EFI checks its source partition/marker/token, card/PROM/assets and required state, then offers a cancellation window.
3. A durable `ATTEMPT.LCK` records intent before the transaction. The application performs the bounded transaction, one FLR and GOP recovery, then verifies final selectors and hands control to Windows.
4. The elevated login task checks current boot ownership, a matching new report, hashes, driver identity, error events and a small CUDA probe. Only success archives the exact report, clears its corresponding lock and queues the next BootNext.
5. Failure stops renewal and retains the attempt record for diagnosis.

The unlock is reapplied at startup. Driver resets and sleep/resume require separate state validation.

## Fast Startup compatibility

On this machine, ordinary Start-menu Shutdown with Fast Startup enabled resumed an old Windows kernel boot timestamp. Raw FAT reads showed a new successful UEFI RUN004 and a pending lock, while normal Windows directory enumeration still showed the previous directory state. The login confirmation code also skipped because the kernel boot timestamp matched its installation boot.

The observed recovery was:

* preserve the raw success report and the current Windows health result;
* obtain owner approval to disable Fast Startup (`HiberbootEnabled` 1 -> 0), saving the original setting;
* owner saves work and performs `shutdown /s /t 0`, then powers on;
* boot plain Windows once, verify the refreshed directory report against the saved hash, and archive the **historical** successful run explicitly as historical;
* rearm the reviewed next attempt only after those checks;
* verify a new complete unlock boot and fresh health result.

Historical runs are archived separately from current-boot confirmation. In the recorded case a subsequent normal full boot produced a new report and a 196.09 TFLOPS successful health result.

The host uses `LastBootUpTime` for deduplication. Fast Startup was disabled on the tested machine. An installer should verify that prerequisite or implement a resume-aware state machine.

## Notification limits

`notifier/Notify-Unlock.ps1` is the existing login-only watcher. A blocked state warns after roughly 50 seconds; missing confirmation warns after roughly four minutes. Success exits, so it does not monitor later GPU resets or loss of unlock state. It uses the same boot timestamp and has a hybrid-boot blind spot. End-to-end popup delivery remains to be verified. A failure before Windows/login cannot display a Windows popup.

Runtime TDR/reset notifications are planned separately from this login-only watcher.

## Recovery principles

Before a trial, keep important data backed up, the original Windows boot path available, the old local files/hash manifest, and a machine-specific recovery plan. If BitLocker/device encryption is enabled, verify recovery access before changing firmware-related state; do not publish recovery keys.

If Windows is accessible, stop renewal using the already-installed and reviewed local host mechanism. Use the installed local configuration for recovery; the published host profile contains placeholders. Check and remove only the owned pending BootNext when disabling; preserve BootOrder and all unrelated entries. Retain failed reports and locks for diagnosis.

For a stopped pre-OS transaction or black screen, follow the agreed local recovery procedure and diagnose the recorded failure stage before another trial. Hardware recovery risks are covered in [DISCLAIMER.md](../DISCLAIMER.md).
