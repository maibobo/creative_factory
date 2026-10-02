# UI v0.9.2 — Engineering Resources + Operator Controls

This revision addresses two usability problems in v0.9.1.

## 1. Resource selection and operations are separated

The top area is no longer a single crowded row.

### 工程资源

- 工程 path + 选择
- 固件 path + 选择固件
- QEMU path + 选择 QEMU

### 运行控制

- 工程分析
- Build
- 启动 QEMU
- 停止
- 环境检查
- 运行测试

`运行测试` remains the primary automatic workflow. The other buttons remain permanently available for manual engineering/debug use.

## 2. Capability Check is no longer a visible operator step

Capability routing is still required internally to decide whether the requested test is runnable, auto-extendable, or unsupported. It is not a manual action and therefore no longer appears as a separate workflow stage or button.

Visible workflow:

```text
工程准备 → 构建 → QEMU运行 → 执行测试 → 结果分析
```

Examples:

```text
GPIO output capability already installed
→ 工程准备 ✓ gpio_output_readback READY
→ 构建 — 本次无需重新构建
```

```text
First GPIO input test
→ 工程准备 ◐ gpio_input_readback 可自动扩展
→ builder installs capability
→ 构建 ▶
→ 工程准备 ✓ gpio_input_readback READY
```

```text
Unsupported SPI request
→ 工程准备 ! spi_transfer MISSING
→ test does not continue into a fake executable plan
```

The detailed capability inventory remains visible in the SIL capability area rather than being promoted to a primary operator control.
