# Capability Builder

## Purpose

The Capability Router answers whether a natural-language requirement is executable by the current firmware. The Capability Builder handles a subset of `capability_missing` results using host-approved deterministic templates.

The LLM never receives arbitrary shell access and never injects model-authored C directly into the project in this v0.5 stage. It identifies the requested capability; the Workbench decides whether a reviewed template is allowed.

## Implemented auto-extension

`gpio_input_readback` is the first auto-extension because the target project already has `RT_USING_PIN` and the real `drivers/drv_gpio.c` path. No RT-Thread/BSP peripheral enablement is required.

Generated runtime path:

```text
ai_test_gpio_input PB.0
  -> rt_pin_get
  -> rt_pin_mode(PIN_MODE_INPUT)
  -> rt_pin_read
  -> RT-Thread PIN framework
  -> drivers/drv_gpio.c
  -> AI SIL virtual external-input boundary
```

The virtual backend applies external HIGH then LOW stimuli. Existing `stuck_low` and `stuck_high` fault modes override readback so the deterministic rule engine can verify detection behavior.

## Automatic flow

For a requirement such as:

```text
测试 PB.0 输入，并覆盖卡低和卡高故障
```

an initial planner result should be:

```text
route=capability_missing
requested_driver=gpio
requested_capability=gpio_input_readback
cases=[]
```

`AI Plan + Run` then:

1. validates that this exact capability is in the safe extension catalog;
2. generates/updates the SIL runtime and test source in `applications/`;
3. keeps `main.c` untouched;
4. reuses the existing reversible `drv_gpio.c` HAL-boundary instrumentation;
5. invokes RT-Thread Studio incremental Managed Build;
6. detects the new firmware;
7. sends the original requirement to the selected GPT / DeepSeek / GLM planner again;
8. now accepts `route=run_existing` for `gpio_input_readback`;
9. executes cases through `ai_test_gpio_input` and waits for `@SIL,RESULT,GPIO_INPUT,...`.

## Safety boundary

This build does not automatically enable SPI/ADC/CAN/UART/I2C/PWM BSP options and does not pretend a disabled driver is tested. For unsupported capabilities the Builder reports the detected driver source/config status and stops without MSH execution.

This is intentional: a new driver should only become READY after the host has a known SIL boundary and deterministic result parser for that driver.
