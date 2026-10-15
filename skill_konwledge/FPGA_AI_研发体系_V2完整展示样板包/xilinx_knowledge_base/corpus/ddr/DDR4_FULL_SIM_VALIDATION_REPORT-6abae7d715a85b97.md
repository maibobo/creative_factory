# DDR4_FULL_SIM_VALIDATION_REPORT

- Category: `ddr`
- Source: `R:\DDR\axi_ddr4_min_2020_2\docs\DDR4_FULL_SIM_VALIDATION_REPORT.md`
- SHA-256: `6abae7d715a85b97d081c356da36eed0f5be9598e673d12833b14815777d0afe`
- Extractor: `text`
- Tags: `ddr4, mig, validation`
- Duplicate sources:
  - E:\ddr_proc\staging_axi_ddr4_min_2020_2\docs\DDR4_FULL_SIM_VALIDATION_REPORT.md

# DDR4 MIG 完整仿真验证报告

## 验证环境

- 远程工程：`C:\project\RTDS\DDR\axi_ddr4_min_2020_2`
- Vivado/XSim：2020.2
- MIG Example Design：`sim_full\mig_example_2020_2\ddr4_axi_0_ex`
- 验证方式：MIG Example Design DDR4器件模型 + 当前 `top_axi_ddr4_bist`

## 分级验证状态

| 阶段 | 测试规模 | 状态 | 结果日志 |
|---|---:|---|---|
| 冒烟仿真 | 32个64-bit字 | 运行后填写 | `sim_full\logs\smoke_vivado.log` |
| 签核仿真 | 4096个64-bit字 | 冒烟通过后自动运行 | `sim_full\logs\signoff_vivado.log` |

## 判定标准

- `init_calib_complete=1`
- `axi_aresetn`在校准完成后释放
- `bist_done=1`
- `bist_pass=1`
- `bist_fail=0`
- `bist_error_count=0`

## 结果

后台流水完成后，根据 `pipeline.status`、两份Vivado日志和WDB波形补充本节。

## 验证边界

本验证覆盖MIG数字仿真模型、DDR4器件模型、AXI4通路和BIST数据比较，不覆盖实现后时序、PCB信号完整性和真实板级校准。
