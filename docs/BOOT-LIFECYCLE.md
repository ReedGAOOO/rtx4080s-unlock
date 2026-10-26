# Boot lifecycle, confirmation and recovery

## Observed local sequence

1. A separately owned firmware boot option points to the reviewed EFI on the test partition. The Windows BootOrder is preserved.
2. `BootNext` schedules **one** attempt. The EFI checks its source partition/marker/token, card/PROM/assets and required state, then offers a cancellation window.
3. A durable `ATTEMPT.LCK` records intent before the transaction. The application performs the bounded transaction, one FLR and GOP recovery, then verifies final selectors and hands control to Windows.
4. The elevated login task checks current boot ownership, a matching new report, hashes, driver identity, error events and a small CUDA probe. Only success archives the exact report, clears its corresponding lock and queues the next BootNext.
5. Failure stops renewal. A retained attempt record is not permission to erase the lock and retry.

This is **reapplication on startup**, not a permanently flashed unlock. It does not guarantee persistence across driver reset, sleep/resume or every restart path.

## Fast Startup is a real compatibility problem

On this machine, ordinary Start-menu Shutdown with Fast Startup enabled resumed an old Windows kernel boot timestamp. Raw FAT reads showed a new successful UEFI RUN004 and a pending lock, while normal Windows directory enumeration still showed the previous directory state. The login confirmation code also skipped because the kernel boot timestamp matched its installation boot.

The observed recovery was:

* preserve the raw success report and the current Windows health result;
* obtain owner approval to disable Fast Startup (`HiberbootEnabled` 1 -> 0), saving the original setting;
* owner saves work and performs `shutdown /s /t 0`, then powers on;
* boot plain Windows once, verify the refreshed directory report against the saved hash, and archive the **historical** successful run explicitly as historical;
* rearm the reviewed next attempt only after those checks;
* verify a new complete unlock boot and fresh health result.

Do not copy this sequence blindly, dismount/modify a cached filesystem without review, or pretend a historical health result validates the new plain-Windows boot. In the recorded case a subsequent normal full boot produced a new report and a 196.09 TFLOPS successful health result.

The existing host implementation uses `LastBootUpTime` for deduplication; it is **not** a general hybrid-resume-safe design. Disabling Fast Startup was part of this machine's approved configuration. Public deployment remains blocked; a future installer should explicitly verify this prerequisite or implement and test an appropriate resume-aware state machine.

## Notification limits

`notifier/Notify-Unlock.ps1` is the existing login-only watcher. A blocked state warns after roughly 50 seconds; missing confirmation warns after roughly four minutes. Success exits, so it does not monitor later GPU resets or loss of unlock state. It uses the same boot timestamp and has a hybrid-boot blind spot. The popup delivery path is not claimed to have been independently end-to-end verified. A failure before Windows/login cannot display a Windows popup.

This release does not silently add a persistent monitor. Runtime TDR/reset event-triggered notifications are future work, not a shipped feature.

## Recovery principles

Before a trial, keep important data backed up, the original Windows boot path available, the old local files/hash manifest, and a machine-specific recovery plan. If BitLocker/device encryption is enabled, verify recovery access before changing firmware-related state; do not publish recovery keys.

If Windows is accessible, stop renewal using the already-installed and reviewed local host mechanism. The published `host/` is a blocked reference, not a recovery command for the author's or reader's machine. Check and remove only the owned pending BootNext when disabling; preserve BootOrder and all unrelated entries. Retain failed reports and locks for diagnosis.

For a stopped pre-OS transaction or a black screen, follow the previously agreed local recovery procedure. Manual power-off can lose data and is not guaranteed to recover hardware. Do not keep rerunning the EFI, automatically reinstall a driver, flash a ROM, clear keys or disable Secure Boot to bypass a refusal. Diagnose the exact failure stage first.
