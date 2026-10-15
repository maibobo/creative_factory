# warning_whitelist

- Category: `pcie`
- Source: `R:\pcie_07\RTDS_test-1ch\RTDS_test-1ch\regression\sim_xdma_rootport\config\warning_whitelist.txt`
- SHA-256: `e4a47cf73eed2e2fb4270b7c847eeaa2e7cba2a21e9abc0b2e07e6d9c60f2cc4`
- Extractor: `text`
- Tags: `pcie, root-port, verification, xdma`
- Duplicate sources:
  - none

# 每行是一个精确正则。仅允许已在 2020.2 官方 XDMA example 或当前 BD 生成中确认的告警。
# Vivado 2020.2 report_ip_status 查询 managed IP 文件对象时的已知属性告警：
^WARNING: \[Vivado 12-3672\] The is_managed property should only be queried on the file object representing this IP\. Use the get_files command to access file objects\.$
^WARNING: \[Vivado 12-3670\] The generate_synth_checkpoint property should only be queried on the file object representing this IP\. Use the get_files command to access file objects\.$
# export_simulation 重编译随 Vivado 提供的 VIP/XPM 源时的精确 2020.2 告警：
^WARNING: \[VRFC 10-3609\] overwriting previous definition of package 'axi4stream_vip_pkg' \[.*/axi4stream_vip_pkg\.sv:51\]$
^WARNING: \[VRFC 10-3669\] re-analyze package '\$unit_axi4stream_vip_axi4streampc_sv' since package 'axi4stream_vip_pkg' is overwritten or removed \[.*/axi4stream_vip_axi4streampc\.sv:1\]$
^WARNING: \[VRFC 10-3669\] re-analyze interface 'axi4stream_vip_if' since interface '\$unit_axi4stream_vip_axi4streampc_sv' is overwritten or removed \[.*/axi4stream_vip_if\.sv:71\]$
^WARNING: \[VRFC 10-3609\] overwriting previous definition of package 'axi_vip_pkg' \[.*/axi_vip_pkg\.sv:51\]$
^WARNING: \[VRFC 10-3669\] re-analyze interface 'axi_vip_if' since interface '\$unit_axi4stream_vip_axi4streampc_sv' is overwritten or removed \[.*/axi_vip_if\.sv:118\]$
^WARNING: \[VRFC 10-8426\] non-net output port 'd_out' cannot be initialized at declaration in SystemVerilog mode \[.*/xpm_fifo\.sv:1909\]$
^WARNING: \[VRFC 10-2821\] generate block is allowed only inside loop and conditional generate in SystemVerilog mode \[.*/xpm_fifo\.sv:3660\]$
^WARNING: \[VRFC 10-986\] literal value truncated to fit in 4 bits \[.*/xdma_v4_1_vl_rfs\.sv:44731\]$
^WARNING: \[VRFC 10-986\] literal value truncated to fit in 4 bits \[.*/xdma_v4_1_vl_rfs\.sv:44732\]$
# 官方 XDMA 模型在 0 ns 的 unique-case 初始化告警：
^WARNING: [0-9]+ns : none of the conditions were true for unique case from File:.*/xdma_v4_1_vl_rfs\.sv:33974$
# 当前 BD 中 AXI ID 宽度由互连合法截取：
^WARNING: \[BD 41-2384\] Width mismatch when connecting pin: '/axi_interconnect_0/s01_couplers/auto_cc/m_axi_rid'\(4\) to pin: '/axi_interconnect_0/s01_couplers/M_AXI_rid'\(5\) - Only lower order bits will be connected\.$
^WARNING: \[BD 41-2384\] Width mismatch when connecting pin: '/axi_interconnect_0/s01_couplers/auto_cc/m_axi_bid'\(4\) to pin: '/axi_interconnect_0/s01_couplers/M_AXI_bid'\(5\) - Only lower order bits will be connected\.$
^WARNING: \[BD 41-2384\] Width mismatch when connecting pin: '/axi_interconnect_0/xbar/s_axi_awid'\(5\) to pin: '/axi_interconnect_0/s00_couplers/M_AXI_awid'\(1\) - Only lower order bits will be connected\.$
^WARNING: \[BD 41-2384\] Width mismatch when connecting pin: '/axi_interconnect_0/xbar/s_axi_arid'\(5\) to pin: '/axi_interconnect_0/s00_couplers/M_AXI_arid'\(1\) - Only lower order bits will be connected\.$
^WARNING: \[BD 41-2384\] Width mismatch when connecting pin: '/axi_interconnect_0/xbar/s_axi_arid'\(5\) to pin: '/axi_interconnect_0/s01_couplers/M_AXI_arid'\(4\) - Only lower order bits will be connected\.$
^WARNING: \[BD 41-2384\] Width mismatch when connecting pin: '/axi_interconnect_0/xbar/s_axi_awid'\(5\) to pin: '/axi_interconnect_0/s01_couplers/M_AXI_awid'\(4\) - Only lower order bits will be connected\.$
^WARNING: \[BD 41-2384\] Width mismatch when connecting pin: '/CONV_DMA_0/M_AXI_RID'\(1\) to pin: '/axi_interconnect_0/S00_AXI_rid'\(5\) - Only lower order bits will be connected\.$
^WARNING: \[BD 41-2384\] Width mismatch when connecting pin: '/CONV_DMA_0/M_AXI_BID'\(1\) to pin: '/axi_interconnect_0/S00_AXI_bid'\(5\) - Only lower order bits will be connected\.$
# BRAM 实际深度只使用地址低位：
^WARNING: \[BD 41-2384\] Width mismatch when connecting pin: '/blk_mem_gen_0/addra'\(32\) to pin: '/axi_bram_ctrl_0/bram_addr_a'\(16\) - Only lower order bits will be connected\.$
^WARNING: \[BD 41-2384\] Width mismatch when connecting pin: '/blk_mem_gen_0/addrb'\(32\) to pin: '/axi_bram_ctrl_0/bram_addr_b'\(16\) - Only lower order bits will be connected\.$
