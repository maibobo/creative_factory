> 历史知识库主题快照；“当前”“已通过”等词只描述原工程记录，不代表2026-10-13重新核验或本轮实测。文末绝对路径仅保留来源身份；阅读本页不依赖这些路径。具体复用条件见本包IP专题。

# DDR/MIG 工程速查

## 当前工程定位

`axi_ddr4_min_2020_2` 是面向 `xcku040-ffva1156-2-i` 的 Vivado 2020.2 最小 DDR4 验证工程。DDR4 数据宽度为 64 bit，MIG 对用户侧提供 AXI4 slave，当前 BIST 参数为 Address 32 bit、Data 64 bit、ID 4 bit、基地址 0、4096 个 word。

当前能明确声称的是 BIST/AXI 行为级仿真通过，以及 2026-07-27 的综合、布局布线、时序报告和 bitstream 产物完成。不能把行为模型或实现完成写成 MIG 器件模型联合仿真、真实 DDR 校准或板卡数据测试通过。

## BIST 流程

1. 等待 `init_calib_complete=1` 且 MIG 的 `ui_clk_sync_rst=0`。
2. 从地址 0 开始执行 4096 次单拍 64-bit 写，共 32 KiB。
3. 第 `index` 个数据使用 `{~index, index}`，便于同时观察高低 32 bit 和地址相关错误。
4. 从同一区域读回，检查数据、`BRESP`、`RRESP` 和 `RLAST`。
5. 错误为 sticky：累加错误数并保存首个错误的地址、期望值、实际值和类型；测试继续运行以暴露更多问题。

当前 LED 语义：校准中 LED0 闪烁、校准完成 LED0 常亮；运行中 LED1 慢闪、通过常亮、失败快闪。

## AXI 主机实现要点

- 目前只发单拍事务：`AWLEN/ARLEN=0`、`AWSIZE/ARSIZE=3`、INCR、`WSTRB=8'hFF`、ID=0。
- AW 和 W 是独立通道，必须分别用 `aw_sent`、`w_sent` 记录握手；不能假定两者同拍被接受。
- 两个写通道都完成后才等待 B；读地址握手后等待 R，并同时检查 `RVALID`、`RRESP`、`RLAST`。
- 当前只允许一个 outstanding transaction，不覆盖乱序、多 ID 或 burst 性能。
- 所有 BIST 状态机均在 MIG `ui_clk` 域运行。不要把板级参考时钟或系统时钟直接当成 AXI 用户时钟。

## 复位与校准

AXI 侧复位只能在下面两个条件都满足后释放：

```text
ui_clk_sync_rst == 0
init_calib_complete == 1
```

工程在此基础上再做两级延迟，避免校准信号刚变化时立即启动主机。BIST start 当前绑定到校准完成，因此一次上电只运行一次；重新运行需要复位。

`init_calib_complete` 只说明 MIG 校准状态，不证明用户数据测试通过。反过来，行为级 AXI slave 没有 MIG 校准过程，也不能证明 DDR 引脚、PHY、内存模型或 PCB。

## 验证层级与当前状态

| 层级 | 验证内容 | 当前结论 |
|---|---|---|
| 行为级 BIST + 寄存器数组 AXI slave | FSM、AW/W 独立握手、反压、response、读回与错误注入 | 已通过；32-word 正常用例通过，bit flip 用例正确检出错误，约 3335 ns 完成 |
| 顶层 + MIG + DDR4 memory model | 校准、`ui_clk`/复位、真实 MIG AXI 数据路径 | 当前报告仍有“运行后填写”占位；现有摘要明确写未执行，不能宣称通过 |
| 综合/实现/DRC/STA | 器件资源、约束、时序与可实现性 | 2026-07-27 产物已完成：route 成功，WNS=0.010 ns、TNS=0，报告称用户时序约束满足；bitstream 前 DRC 为 0 Error/2 Warning |
| bitstream | 配置文件生成 | `top_axi_ddr4_bist.bit` 已生成；这只证明构建流程完成 |
| 板卡 | 真实 DDR4 校准、32 KiB 读写及稳定性 | 未执行；仍需板卡/JTAG 和 LED/ILA/日志证据 |

实现日志中的两条 DRC warning 仍需在板级签核前处理：未设置 `CFGBVS/CONFIG_VOLTAGE`，以及 MIG 校准逻辑中的若干 no-routable-load 网络。知识库不把“0 Error”自动等同于这些 warning 已经接受或无风险。

## 当前覆盖不足

- 无 burst、无多 outstanding、无多 ID。
- 只测 32 KiB、基地址 0 和一种数据模式。
- 没有硬件 watchdog；总线或 MIG 永久不响应时可能一直等待。
- 只能通过 reset 重新运行。
- 尚未覆盖地址边界、bank/row 组合、随机模式、walking 1/0、长时间压力和温度/电压变化。

下一阶段应补完 MIG/DDR4 器件模型联合仿真、收口实现 warning，再按“burst 与 4 KB 边界 → 多数据模式与地址区域 → 超时/故障注入 → 板级校准与长稳压力”的顺序扩展，避免用后一级结果掩盖前一级协议错误。

## 主要证据

- `R:\DDR\axi_ddr4_min_2020_2\README.md`
- `R:\DDR\axi_ddr4_min_2020_2\docs\DDR4_MIN_BIST_DESIGN_AND_VERIFICATION.md`
- `R:\DDR\axi_ddr4_min_2020_2\docs\DDR4_FULL_SIM_VALIDATION_REPORT.md`
- `R:\DDR\axi_ddr4_min_2020_2\docs\DDR_AXI_SIM_VALIDATION_AND_CONVERSATION_SUMMARY.md`
- `R:\DDR\axi_ddr4_min_2020_2\rtl\axi_ddr_bist.v`
- `R:\DDR\axi_ddr4_min_2020_2\rtl\top_axi_ddr4_bist.v`
- `R:\DDR\axi_ddr4_min_2020_2\prj\axi_ddr4_min_2020_2.runs\impl_1\runme.log`（只作精选实现证据，不把整个 `.runs` 纳入语料）
- `R:\DDR\axi_ddr4_min_2020_2\prj\axi_ddr4_min_2020_2.runs\impl_1\top_axi_ddr4_bist_timing_summary_routed.rpt`
