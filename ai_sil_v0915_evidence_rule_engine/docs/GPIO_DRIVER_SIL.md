# GPIO Driver SIL path

## Goal

Prove that the generated test executes through the project's existing RT-Thread GPIO driver instead of only testing a standalone virtual GPIO model.

## Runtime path

```text
ai_test_gpio
-> rt_pin_get / rt_pin_mode / rt_pin_write / rt_pin_read
-> RT-Thread PIN framework
-> _stm32_pin_ops
-> stm32_pin_get / stm32_pin_mode / stm32_pin_write / stm32_pin_read
-> Virtual GPIO hardware boundary
```

The driver parser, pin-number mapping, RT-Thread device registration, operation dispatch and driver functions remain real.

## SIL hook

Only the HAL-facing calls in `drivers/drv_gpio.c` are redirected while a SIL case is active:

- `HAL_GPIO_Init` -> `ai_sil_gpio_mode`
- `HAL_GPIO_WritePin` -> `ai_sil_gpio_write`
- `HAL_GPIO_ReadPin` -> `ai_sil_gpio_read`

A runtime `ai_sil_gpio_is_active()` guard keeps normal HAL behavior outside a test.

The mode hook receives the driver's already-computed `GPIO_InitTypeDef`, so the testcase can verify that `PIN_MODE_OUTPUT` was mapped by the real driver to `GPIO_MODE_OUTPUT_PP` with `GPIO_NOPULL`.

## Reversibility

Before first instrumentation, Workbench copies:

```text
drivers/drv_gpio.c
```

to:

```text
.ai_sil_backup/drv_gpio.c.orig
```

Instrumentation markers are idempotent, so repeated Generate actions do not stack patches.

## Normal case

```text
ai_test_gpio PB.0
```

Expected evidence includes:

```text
@SIL,CHECK,write_high,requested=1,observed=1
@SIL,CHECK,write_low,requested=0,observed=0
@SIL,CHECK,mode_output,...
@SIL,DRIVER,drv_gpio.c,...
@SIL,RESULT,GPIO,...
```

## Fault cases

```text
sil_gpio_fault_stuck_low
ai_test_gpio PB.0
```

or:

```text
sil_gpio_fault_stuck_high
ai_test_gpio PB.0
```

These faults are injected below the real driver at the virtual hardware boundary, which makes the failure observable through the normal RT-Thread PIN API path.
