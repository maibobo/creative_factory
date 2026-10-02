# GPIO Input Auto-Extension — v0.8

## Purpose

Demonstrate that the Workbench can recognize a requested behavior that is not yet installed, safely add a predefined SIL capability, rebuild the firmware, re-route the original requirement, and then execute it.

## Safety boundary

The builder is deliberately limited to `gpio_input_readback`. It reuses the already-enabled RT-Thread PIN framework and `drivers/drv_gpio.c`. It does not grant the model arbitrary source-edit or shell execution authority.

## Generated capability

```text
ai_test_gpio_input <pin>
  -> rt_pin_get
  -> rt_pin_mode(PIN_MODE_INPUT)
  -> virtual external HIGH / LOW stimulus
  -> rt_pin_read
  -> RT-Thread PIN framework
  -> drivers/drv_gpio.c
  -> Virtual GPIO hardware boundary
```

Supported injected faults:

```text
none
stuck_low
stuck_high
```

## Expected cases

```text
Normal:
  external HIGH -> read HIGH
  external LOW  -> read LOW
  functional PASS

Stuck low:
  external HIGH -> read LOW
  external LOW  -> read LOW
  functional FAIL, detection PASS

Stuck high:
  external HIGH -> read HIGH
  external LOW  -> read HIGH
  functional FAIL, detection PASS
```

## UI lifecycle

```text
IN ◐ EXT
  -> capability_missing / safe template available
IN ◐ BUILD
  -> generated sources + RT-Thread Studio incremental build
IN ●
  -> firmware contains ai_test_gpio_input and can be planned as run_existing
```

## Evidence

Each completed case exposes:

- functional verdict
- TestPlan expected verdict
- regression detection result
- external HIGH/LOW readback
- deterministic failed rules
- drv_gpio mode/write/read counters
- HAL mode/pull evidence when supplied by the runtime
