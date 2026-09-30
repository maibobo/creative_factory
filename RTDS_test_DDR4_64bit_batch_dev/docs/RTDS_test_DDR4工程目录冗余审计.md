
审计时间：2026-08-20  
执行原则：本次只检查、分类和提出清理建议，未删除审计发现的候选目录。

## 1. 结论


- 上述两组强清理候选合计约 **642.38 MiB**。
- 名称带 `example/exdes` 的 Aurora 源有一部分被当前 XPR 直接引用，不能仅凭名称删除。
- 新工程 `ip_user_files` 的部分 BD 仿真导出已确认陈旧，但远程 Vivado 当前存在 IP Integrator 辅助 Tcl 异常；在完整仿真导出恢复前，建议暂留以便问题复盘。

## 2. 顶层主要目录体积

| 路径 | 体积（MiB） | 文件数 | 分类 |
|---|---:|---:|---|
| `external_snapshot` | 110.01 | 301 | 部分生产源被 XPR 直接引用，不能整体删除 |
| `regression` | 42.74 | 345 | 回归源、日志、WDB；交付验证材料，保留 |
| `sim` | 3.02 | 72 | 测试源与部分工作产物混合，不能整体删除 |
| `xsim.dir` | 2.32 | 48 | 可再生成工作目录，可选清理 |
| `xsim_top_bridge_work` | 0.93 | 34 | 可再生成工作目录，可选清理 |
| `xsim_pcie_syntax_work` | 0.07 | 9 | 可再生成工作目录，可选清理 |

## 3. 强清理候选

以下项目可在用户授权后精确清理。清理前应再次确认 Vivado/XSim 进程均已退出。

| 路径 | 体积 | 理由 | 影响/恢复 |
|---|---:|---|---|

强清理候选预计回收约 **642.38 MiB**。

## 4. Example/Exdes 审计

### 4.1 不能直接删除的文件


- `external_snapshot\fdma_aurora_brg\fdma_aurora_brg.srcs\sources_1 - loop_validate\ip\aurora_64b66b_0\aurora_64b66b_0.xci`
- `...\imports\aurora_64b66b_0_ex\imports\aurora_64b66b_0_cdc_sync_exdes.v`
- `...\aurora_64b66b_0_example_axi_to_ll.v`
- `...\aurora_64b66b_0_example_ll_to_axi.v`
- `...\aurora_64b66b_0_exdes.v`
- `...\aurora_64b66b_top.v`
- 同一 `sources_1 - loop_validate` 下的 FDMA RX/TX/top 和 CDC 源。

这些文件虽然名称包含 `example/exdes`，但已经成为现有 Aurora 生产封装的一部分；不重构 XPR/RTL 前不能删除。

`regression\export_xdma_example_rp.tcl` 也应保留。它是导出 Xilinx Root Port 官方参考模型的回归脚本，不是误复制的独立 example 工程。

### 4.2 可选清理候选

- `external_snapshot\fdma_aurora_brg\fdma_aurora_brg.gen`：27.17 MiB，当前 XPR 未直接引用；其中真正名为 `example_design` 的目录约 0.159 MiB。可在确认 Aurora XCI 能从保留的 `.srcs` 独立生成后清理。

不建议只删除 `example_design` 的零散文件。更稳妥的做法是保留当前活跃 `.srcs\sources_1 - loop_validate`，按目录整体清理未引用的 `.gen`。

## 5. 可再生成缓存与工作目录

以下内容通常可以清理，但不影响源工程审计结论：

- 根目录 `.Xil`、`vivado*.jou/log`、`webtalk*.jou/log`、`xvlog/xelab` 根日志。
- 根目录 `xsim.dir`、`xsim_pcie_syntax_work`、`xsim_top_bridge_work`。
- `sim\ddr4_backend` 下的 `work/xsim.dir` 等运行产物；应保留测试台源和 `reports\compile` 中的通过日志。
- regression 子目录中的 `.Xil/xsim.dir/work` 可再生成，但 `logs` 中的 WDB/比较记录属于验证证据，是否清理应按交付策略决定。

## 6. 建议保留

- `rtl`、`tcl`、`scripts`、`sim` 中的测试源和边界 stub。
- `docs`、`reports`、`logs`、`manifest`、`golden_snapshot`。
- `regression` 的测试源、官方 Root Port/TPI 参考和当前 PASS 证据。
- `external_snapshot\...\fdma_aurora_brg.srcs\sources_1 - loop_validate`，因为当前 XPR 有直接引用。

## 7. 推荐清理顺序

3. 清理根目录和本轮定向验证产生的 XSim 工作目录，只保留脚本、测试源和 `reports\compile` 日志。
4. 可选删除未被 XPR 引用的 `external_snapshot\...\fdma_aurora_brg.gen`。
5. 暂不删除新名 `ip_user_files` 和 regression 证据。
6. 清理后重跑三项门槛：基本冒烟、TOP 定向编译/Elaborate、DDR4_REAL 后端编译/Elaborate。
7. 最后重新生成 `manifest\final_sha256.txt`。

## 8. 当前处置

本审计仅形成报告，未删除上述候选。等待用户明确授权后再执行精确清理和回归。
