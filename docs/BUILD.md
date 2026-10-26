# Building and checking the public reference

The commands below compile and test the reference source. `GU_PUBLIC_REFERENCE_BUILD` disables hardware execution; target configuration is covered in [PORTING.md](PORTING.md).

## Dependencies

* Python 3.10+ for source checks/build wrappers; Python 3.14+ only for the upstream `.tar.zst` asset preparation path.
* Zig **0.14.1**, downloaded from https://ziglang.org/download/ .
* Git and EDK2 headers at `c1415771ac592ad8509351c46cd3cda4f38d7d52`.
* Windows PowerShell 5.1+ for the host policy tests.
* Linux/WSL GCC with ASan/UBSan for optional full application replay.
* CUDA **12.8** compiler for optional microbenchmark cubins. The benchmark runner uses the installed CUDA driver API on Windows or WSL; it does not install a GPU driver.

From the repository root:

```text
python tools/check_publication.py
python tools/fetch_headers.py
python source/build_candidate.py --zig /path/to/zig --edk2 deps/edk2
```

On Windows, substitute the absolute path to `zig.exe`. The output is `source/build-candidate/RTXAUTO.EFI`, excluded from Git. The build report explicitly records `reference_only=true` and `hardware_execution_tested=false`.

The original locally tested v0.6.2 EFI was 81,920 bytes with SHA-256 `c0a576c2427bae95d205c7b21dafcbe42a2b1832488601eb95c41cc9a703862c`. The public reference has different identifiers and a disabled source-matching gate; its hash and hardware-validation status are recorded separately.

## Windows host policy tests

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\host-tests.ps1
```

The suite loads only `PolicyOnly`, checks malformed records, selector/result gates, health decisions, boot ownership, atomic state writes and UTF-8 handling. It writes fixtures into `local/`, loads C# types and constructs a synthetic EFI load-option byte array. It does not call the firmware read/write API or launch CUDA. `local/` is ignored by Git.

`host/AutoUnlock.ps1` is blocked for deployment in this publication. A reviewed local port must regenerate the firmware path, identifiers, host/stage hash manifest and CUDA cubin; replace the synthetic values as part of the reviewed local port.

## Local firmware preparation (optional, not needed for reference compilation)

Read the licenses and upstream provenance before downloading inputs. Firmware is not part of this repository.

```text
python tools/prepare_assets.py
```

This obtains pinned inputs and writes `local/ASSETS`. It does not install or execute an EFI. The helper verifies `ASSETS-MANIFEST.json`; investigate any input hash mismatch before continuing. Keep downloaded archives, extracted binaries, generated payloads and ROMs private. Network availability and third-party download URLs can change.

## Full CPU application replay

The historical 113-case test uses the exact privately retained preflight capture, PROM and locally generated firmware. Those inputs are deliberately not distributed. With the original privately held matching inputs:

```text
python source/replay_application.py --edk2 /path/to/edk2 --evidence /path/to/private-preflight-capture --assets /path/to/local/ASSETS --out /path/to/local/replay-output
```

Run on Linux/WSL with GCC. GPU accesses are mocked, but ROM/firmware parsing uses the local bytes. The capture hash is pinned; different hardware requires a separately reviewed fixture and profile. A public clone alone cannot reproduce this full suite without those inputs. Historical reports and fresh replay results are recorded separately.

## Optional short CUDA probe

This is real GPU compute. Stop conflicting GPU workloads first. It neither applies nor removes an unlock.

```text
nvcc -cubin -arch=sm_89 -O3 benchmarks/fp8_short.cu -o local/fp8_short.cubin
python benchmarks/fp8_short_runner.py local/fp8_short.cubin --sha256 YOUR_CUBIN_SHA256 --expect-uuid YOUR_GPU_UUID --expect-power-limit YOUR_POWER_LIMIT --iters 256 --reps 3
```

Use a local SHA-256 and the GPU UUID/power limit from `nvidia-smi`; do not upload the UUID. Keep FP8 at the documented 256-iteration protocol. The 10,000-iteration accumulation check failed and is unresolved; retain the numerical assertion when investigating it. CUDA compiler/driver errors or numerical mismatches must stop the run. Iteration counts here apply to this probe’s accumulation protocol.

For the host health cubin, compile `benchmarks/tensor_modes_issue.cu` with the same `-cubin -arch=sm_89 -O3` flags. A reviewed installer must pin the resulting hash, not copy the private deployment manifest.
