# UI v0.9.1 — Operator Controls and Real Pipeline State

This revision keeps the v0.9 workbench structure but restores the manual controls needed during embedded-driver debugging.

## Main operator controls

The project strip keeps these actions visible at all times:

- 工程分析
- Build
- 启动 QEMU
- 停止
- 环境检查
- 运行测试

Low-frequency operations such as rebuilding a SIL capability, firmware detection, and SIL verification remain internal/advanced operations.

## Pipeline semantics

The six-stage pipeline is a status display, not a set of buttons:

1. 工程分析
2. 能力检查
3. 构建
4. QEMU 运行
5. 执行测试
6. AI 诊断

Typical states:

### Existing GPIO output capability

```text
✓ 工程分析
✓ 能力检查   gpio_output_readback · READY
— 构建       本次无需重新构建
○ QEMU运行   未启动
○ 执行测试   等待运行
○ AI诊断     等待执行结果
```

### First-time GPIO input auto extension

```text
✓ 工程分析
◐ 能力检查   gpio_input_readback · 可自动扩展
○ 构建       等待 Capability 安装
```

During installation:

```text
▶ 能力检查   正在安装 gpio_input_readback
▶ 构建       正在构建 Firmware
```

After the build:

```text
✓ 能力检查   gpio_input_readback · READY
✓ 构建       Firmware Ready
```

### Unsupported capability

```text
! 能力检查   spi_transfer · MISSING
— 构建       能力缺失，暂不构建
```

## QEMU state

`QEMU Running` alone is not considered fully ready.

```text
▶ QEMU运行   进程已启动，等待 RT-Thread
✓ QEMU运行   RT-Thread Ready
✓ QEMU运行   SIL Runtime Ready
```
