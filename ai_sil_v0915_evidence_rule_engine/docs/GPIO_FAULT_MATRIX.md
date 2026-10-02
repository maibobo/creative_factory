# GPIO Fault Matrix

This v0.5 extension adds batch fault-regression on top of the real GPIO driver SIL path.

## What runs

The button **Run Fault Matrix** reuses the currently running firmware and executes three cases without rebuilding:

1. `sil_reset` -> `sil_gpio_fault_none` -> `ai_test_gpio <pin>`
2. `sil_reset` -> `sil_gpio_fault_stuck_low` -> `ai_test_gpio <pin>`
3. `sil_reset` -> `sil_gpio_fault_stuck_high` -> `ai_test_gpio <pin>`

The individual functional verdicts are expected to be:

- none: PASS
- stuck_low: FAIL (HIGH readback must fail)
- stuck_high: FAIL (LOW readback must fail)

The matrix itself is PASS when all three expected behaviors are observed. This distinguishes a deliberately injected functional failure from a failure of the regression system itself.

## Driver path

Each case still follows:

`rt_pin_* -> drivers/drv_gpio.c -> AI SIL GPIO hardware boundary -> virtual GPIO state/fault`

No rebuild is performed between matrix rows.
