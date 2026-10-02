# v0.9 Modern Workbench UI

This release reorganizes the native Windows UI around the operator workflow instead of individual engineering buttons.

## Main flow

```text
Project
  -> Engineering Analysis
  -> Test Capability Preparation
  -> Build
  -> QEMU Runtime
  -> Execute Test
  -> AI Diagnosis
```

The underlying GPIO SIL, Capability Router/Builder, RT-Thread Studio Build, QEMU runner, deterministic Rule Engine, AI Diagnosis and HTML report logic are preserved from v0.8.2.

## UI changes

- Main title: `装置平台技术预研部`
- Product subtitle: `AI SIL 测试工作台`
- Project/runtime strip is compact; engineering controls are no longer a row of equally weighted buttons.
- Workflow stepper uses `测试能力准备` instead of `生成 SIL` to avoid implying that SIL code must be regenerated for every run.
- Top-level primary action is `运行测试` and still invokes the existing AI Plan + capability routing + execution path.
- Requirement card keeps the natural-language prompt and AI planner configuration.
- TestPlan supports `结构化视图` and `JSON` views. JSON remains available for engineering inspection but is not the default view.
- Result pane explicitly states that the deterministic Rule Engine owns PASS/FAIL and AI only explains execution evidence.
- Fault Matrix now separates semantic `Detection` (`Detected`, `Not Detected`, `Mismatch`, `Timeout`) from final `Case Result` (`PASS`/`FAIL`).
- SIL capability navigation exposes current scope: GPIO ready, other peripheral families missing/not installed.
- Bottom Build/UART/Agent console remains available as an IDE-style engineering panel.
- Responsive `WM_SIZE` layout remains enabled.

## SIL / AI relationship represented in the UI

`测试能力准备` is an infrastructure stage, not a per-test requirement. If the requested capability is already installed, the Agent skips generation/build and runs the TestPlan. If a safe built-in capability extension is missing (currently GPIO input/readback), Capability Builder can generate/build it and then continue the original task.

## Current scope

- GPIO output/readback: READY
- GPIO input/readback: READY or safe auto-extension depending on selected project state
- GPIO IRQ / ADC / SPI / CAN / UART / I2C / PWM: not installed by the current Builder

The navigation entries for future capabilities are status/context views, not claims that those drivers are already supported.
