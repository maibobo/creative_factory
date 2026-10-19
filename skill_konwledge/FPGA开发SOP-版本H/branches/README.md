# 并行专项分支

主 SOP 面向传统 RTL/Vivado 前端开发。以下能力共享 G0、G3、G8、G10 的质量思想，但不强制套用 G1-G7 的 RTL 细节。

## HLS 分支

推荐入口：

```text
hls-matlab-to-cpp（如输入来自 MATLAB）
  → hls-architect
  → hls-optimize
  → hls-run-flow
  → hls-synth-report / hls-cosim-report / hls-impl-report
```

HLS 的 csim、csynth、cosim、impl 是 HLS 自身的执行链，报告和 QoR 基线不能与 RTL Lint 或 RTL 仿真报告混用。

## Vitis AI 分支

推荐使用 orchestrator：

```text
vai-quantization-guide
vai-flag-configuration
vai-custom-op
```

由 orchestrator 按模型量化、分区、性能或 Custom Op 需求调用具体 helper skill。

## Versal / Segmented Configuration / DFX 分支

推荐入口：

```text
segcfg-overview
  → segcfg-design-considerations
  → segcfg-design-check
  → segcfg-pl-reload / segcfg-aie / segcfg-hw-manager
```

这类项目必须额外记录 boot.pdi、pld.pdi、器件代际、NoC/DDR/CPM/PCIe 约束和硬件编程证据。

