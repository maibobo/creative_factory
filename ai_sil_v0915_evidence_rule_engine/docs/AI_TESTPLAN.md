# AI Capability Route + TestPlan layer

## Purpose

The LLM is now used for two tightly constrained steps in one structured response:

1. route a natural-language requirement against installed SIL capabilities;
2. generate an executable TestPlan only when the full request is covered by an installed capability.

Existing Build/QEMU/UART/driver-SIL paths remain deterministic.

## Security / determinism boundary

```text
Natural language
  -> GPT / DeepSeek / GLM
  -> capability route + unified TestPlan JSON
  -> Workbench semantic validator
       | run_existing        -> fixed MSH command compiler
       | capability_missing  -> STOP, no MSH
       | needs_clarification -> STOP, no MSH
  -> QEMU / RT-Thread
  -> @SIL,RESULT
  -> deterministic rule engine
```

No provider can supply arbitrary MSH commands.

## Supported example

Requirement:

```text
测试 PB.0 输出，并覆盖典型 GPIO 卡死故障
```

Expected class of response:

```json
{
  "version": "1.0",
  "route": "run_existing",
  "requested_driver": "gpio",
  "requested_capability": "gpio_output_readback",
  "reason": "当前 SIL 已支持 GPIO 输出和高低电平回读以及卡低/卡高故障注入",
  "driver": "gpio",
  "target": "PB.0",
  "cases": [
    {"id":"GPIO_NORMAL","fault":"none","expected":"PASS","description":"正常高低电平写入回读"},
    {"id":"GPIO_STUCK_LOW","fault":"stuck_low","expected":"FAIL","description":"检测输出卡低"},
    {"id":"GPIO_STUCK_HIGH","fault":"stuck_high","expected":"FAIL","description":"检测输出卡高"}
  ]
}
```

## Unsupported example

Requirement:

```text
测试 SPI1 10MHz 收发
```

Expected class of response:

```json
{
  "version": "1.0",
  "route": "capability_missing",
  "requested_driver": "spi",
  "requested_capability": "spi_transfer",
  "reason": "当前固件未安装 SPI SIL 测试能力",
  "driver": "spi",
  "target": "SPI1",
  "cases": []
}
```

The Workbench displays the missing capability and stops before MSH/QEMU execution.
