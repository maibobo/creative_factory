# AI SIL Test Workbench v0.9.13 — Command Contract Auto-Repair

## Purpose

Fixes generated-harness cases where the AI bundle metadata says one command/capability identity but the compiled RT-Thread harness registers or emits another one.

Example fixed by this release:

- Bundle `test_command`: `ai_sil_gpio_toggle_pattern`
- Actual RT-Thread command: `gpio_toggle_pattern_test`
- Actual smoke frame: `@SIL,AI_SMOKE,ai_sil_gpio_toggle_pattern,...`
- Expected capability identity: `gpio_toggle_pattern`

v0.9.13 treats this as a generated Harness command/protocol contract error. It is **not** a GPIO driver FAIL and does not require manual C edits.

## Strict pre-Build validator

Before writing/building generated files, the Host now requires:

1. `test_command` is one `ai_sil_*` token.
2. `smoke_command` first token equals `test_command` exactly.
3. Generated C contains an actual `MSH_CMD_EXPORT(<test_command>, ...)` registration. Merely mentioning the command in a comment/string is no longer enough.
4. `AI_SMOKE` uses the top-level `capability` exactly as its capability field.
5. `GEN_RESULT` uses the top-level `capability` exactly as its capability field.

If any item is wrong, Bundle Repair runs automatically before Build.

## Runtime command/protocol auto-repair

Build PASS is followed by the QEMU Capability Probe. If Build/QEMU/MSH transport is alive but the generated harness still returns an `AI_SMOKE_TIMEOUT`, `AI_SMOKE_MISMATCH`, or invalid `AI_SMOKE` status, Workbench now:

1. Captures the probe error and UART evidence.
2. Sends the current generated bundle + evidence to the Repair model.
3. Restricts the repair scope to generated `applications/ai_sil_ai_*.c/.h` command-registration / smoke-protocol code.
4. Re-validates the strict contract.
5. Rebuilds the real RT-Thread project.
6. Re-runs the QEMU Capability Probe.
7. Repeats until READY, user stop, no-progress, API failure, or a non-generated infrastructure blocker.

The repair is not allowed to modify `drv_*.c`, BSP/configuration, or weaken functional Test Case acceptance rules.

## Functional boundary retained

- Build error => `BUILD ERROR`, Test NOT RUN.
- Generated MSH/protocol contract error => automatically repair the Harness infrastructure.
- Capability READY => run the formal Test Case.
- DUT functional mismatch => Rule Engine `TEST FAIL`; it does not trigger command/protocol repair.

## Validation

- `GOOS=windows GOARCH=amd64 CGO_ENABLED=0 go vet main.go` — PASS
- Windows x64 GUI build — PASS
- Windows x64 debug build — PASS
- Mock QEMU console x64 build — PASS
