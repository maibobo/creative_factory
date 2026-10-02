# AI SIL Test Workbench v0.9.14 — Baseline-Aware Harness Regeneration

## Why this release exists

A generated capability can compile, register its MSH command, pass the infrastructure probe, and still contain incorrect test-harness logic. The observed `gpio_toggle_pattern` case is the motivating example:

- generated command/protocol: READY
- generated formal test: `FAIL, mismatch ... write=1 read=0`
- built-in `ai_test_gpio PB.0`: PASS
- built-in `ai_test_gpio PC.0`: PASS

v0.9.14 stops treating that contradiction as a valid GPIO-driver verdict. A bad test harness is a bad ruler and is automatically invalidated/regenerated.

## Verified GPIO SIL lifecycle

The built-in GPIO baseline activates the virtual GPIO interception only inside the SIL case lifecycle:

`ai_sil_gpio_begin_case()` -> `rt_pin_mode(..., PIN_MODE_OUTPUT)` -> `rt_pin_write/read` -> `ai_sil_gpio_end_case()`

Generated `gpio_toggle_pattern` harnesses are now required to use the same lifecycle. This matters because `drv_gpio.c` redirects its selected HAL boundary to `virtual_gpio` only while the SIL case is active. A generated harness that skips the lifecycle may compile and run, but QEMU readback can remain LOW and produce a false functional FAIL.

The pre-Build validator now requires for `gpio_toggle_pattern`:

- `#include "ai_sil_gpio_backend.h"`
- `ai_sil_gpio_begin_case()` and `ai_sil_gpio_end_case()`
- `rt_pin_mode(..., PIN_MODE_OUTPUT)`
- `rt_pin_write(...)`
- `rt_pin_read(...)`

The CodeGen prompt also receives the verified built-in GPIO test/runtime/backend sources as reference context.

## Baseline-aware validation

For `gpio_toggle_pattern`, when a generated expected-PASS case reports functional FAIL, Workbench automatically runs the deterministic control path on the same pin:

`sil_reset -> sil_gpio_fault_none -> ai_test_gpio <pin>`

If the baseline PASSes while the generated harness FAILs:

- no DUT/driver FAIL is issued from that generated result;
- the current generated revision becomes `INVALID_HARNESS`;
- evidence is stored under `.ai_sil/last_failure/<capability>/harness_validation.txt`;
- Workbench generates a fresh revision from the original requirement;
- the failed evidence and verified baseline are fed back to CodeGen;
- Build -> QEMU Probe -> formal Test is repeated automatically.

This policy is intentionally scoped to a capability with a known equivalent foundation. v0.9.14 does **not** use GPIO output baseline to invalidate unrelated capabilities such as `gpio_irq`.

## Versioned capability behavior

Generated manifests now carry a `revision` field.

- verified `READY` revision: reusable
- `INVALID_HARNESS` revision: not advertised to Planner as installed/ready
- fresh regeneration increments revision (`r1 -> r2 -> r3 ...`)
- compiler/protocol repairs within one generated revision keep the same revision number

An existing v0.9.13 manifest without a revision is treated as `r1` for migration.

## Automatic recovery of an already cached bad capability

If a previously READY `gpio_toggle_pattern` is executed and the baseline proves a generated-harness contradiction, `executePlanLifecycleSync` automatically converts it back into an engineering/regeneration task. The user is not asked to edit generated C.

## Anti-overfitting guard

Runtime regeneration is not allowed to mutate the Harness forever just to chase a PASS. If independent freshly generated revisions reproduce the same functional failure signature, Workbench stops blind regeneration and reports `NEEDS_DIAGNOSIS`. That condition is not automatically labeled Driver FAIL; it means the deterministic baseline is no longer sufficient to distinguish a stateful DUT/SIL issue from a repeated Harness mistake.

## Validation

- `GO111MODULE=off GOOS=windows GOARCH=amd64 go vet agent_src/main.go` — PASS
- Windows x64 GUI build — PASS
- Windows x64 debug build — PASS
- Mock QEMU console x64 build — PASS
