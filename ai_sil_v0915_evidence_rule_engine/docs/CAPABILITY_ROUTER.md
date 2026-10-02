# AI Capability Router

The user no longer needs to use a fixed GPIO prompt. GPT, DeepSeek, or GLM first classifies the natural-language requirement against the capabilities that are actually installed in the Workbench.

The router returns exactly one route:

```text
run_existing        -> an installed READY SIL capability can execute it
capability_missing  -> a new driver/feature adapter is required; no MSH command is sent before the Builder validates an extension
needs_clarification -> the request is too ambiguous to execute safely; no MSH command is sent
```

Current capability catalog:

```text
GPIO digital output / write-readback   READY
GPIO input / external-level readback   EXTENDABLE, then READY after Capability Builder
GPIO IRQ                               NOT INSTALLED
ADC/SPI/CAN/UART/I2C/PWM               NOT INSTALLED

Targets for installed GPIO capabilities: PA.0 .. PK.15
Faults: none / stuck_low / stuck_high
```

Examples:

```text
测试 PC.3 正常输出
=> run_existing

测试 PB.0，并覆盖卡低和卡高
=> run_existing

测试 PB.0 输入，并覆盖卡低和卡高
=> capability_missing on first route; AI Plan + Run can auto-extend gpio_input_readback, rebuild, re-plan, then execute

测试 PB.0 外部中断
=> capability_missing (GPIO IRQ is not installed)

测试 SPI1 10MHz 收发
=> capability_missing (SPI SIL is not installed)

帮我测试一下 GPIO
=> needs_clarification (pin/behavior is ambiguous)
```

The semantic validator is authoritative. `capability_missing` and `needs_clarification` plans are required to contain zero executable cases. A missing route reaches MSH only after the host Capability Builder installs an approved template and a second planner pass returns `run_existing`. Therefore a model cannot smuggle MSH work into an unsupported route.
