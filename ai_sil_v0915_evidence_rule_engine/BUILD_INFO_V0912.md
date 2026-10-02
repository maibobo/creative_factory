# AI SIL Test Workbench v0.9.12 — Capability READY Semantics

## Purpose
Separates **test-capability readiness** from the **functional verdict of the driver under test**.

A generated harness is no longer rolled back merely because an old-style `AI_SMOKE` branch observes a functional mismatch such as `MISMATCH_HIGH_READ_0`.

## New state model

1. **Bundle/Validator** — generated package structure is valid.
2. **Build** — generated `applications/ai_sil_ai_*.c/.h` compiles and links into `rtthread.bin`.
3. **Capability Probe** — QEMU/RT-Thread starts, the generated MSH command is callable, and an `@SIL,AI_SMOKE,...` protocol frame is returned.
4. **Capability READY** — the harness is considered installed and executable.
5. **Formal Test Case** — the generated command runs a real scenario and emits `@SIL,GEN_RESULT,...`.
6. **Rule Engine Verdict** — the host compares observed functional result against the TestPlan expected result and determines Test PASS/FAIL.

## Important semantic boundary

- Build failure => `BUILD ERROR`, test is **NOT RUN**.
- Command/protocol readiness failure => `CAPABILITY ERROR`, test is **NOT RUN**.
- Driver/readback/IRQ/ADC/etc. mismatch => **formal Test FAIL**, not Capability FAIL.
- Formal Test FAIL does **not** roll back a successfully built generated harness.

## Compatibility with existing generated harnesses

Older generated harnesses may perform functional checks inside their `smoke` branch and return, for example:

`@SIL,AI_SMOKE,gpio_toggle_pattern,FAIL,MISMATCH_HIGH_READ_0`

v0.9.12 treats receipt of this valid protocol frame as proof that the command/protocol path is alive. The functional FAIL is logged as a hint and carried into the formal test phase; it no longer marks the capability invalid and no longer triggers rollback.

New CodeGen/Repair prompts explicitly require `AI_SMOKE` to be infrastructure-only. Functional checks belong in normal scenarios and `@SIL,GEN_RESULT`.

## Build isolation retained

- Only `applications/ai_sil_ai_*.c/.h` are live generated build sources.
- `.ai_sil` remains metadata/history only, with non-buildable `*.snapshot` source history.
- Build failures are still continuously repaired when compiler errors point to AI-generated files.
- Compile repair never automatically edits original driver/BSP/config files.

## Validation

- `GOOS=windows GOARCH=amd64 CGO_ENABLED=0 go vet main.go` — PASS
- Windows x64 GUI build — PASS
- Windows x64 debug build — PASS
- Mock QEMU console x64 build — PASS
