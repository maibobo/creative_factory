# tests

- Category: `pcie`
- Source: `R:\pcie_07\RTDS_test-1ch\RTDS_test-1ch\regression\sim_xdma_rootport\tb\tests.vh`
- SHA-256: `fd835ba2b1dc7a8c85bacf97d53ca82b9c14c31db829d17114fb0acd168e9209`
- Extractor: `text`
- Tags: `pcie, root-port, verification, xdma`
- Duplicate sources:
  - none

```verilog
// 官方 pci_exp_usrapp_tx.v 在完成链路、枚举、BAR 初始化和 XDMA BAR 搜索后
// include 本文件。保持 vendor 文件不变，仅增加 RTDS 最小闭环入口。
else if (testname == "rtds_minimum") begin
    board.run_rtds_minimum;
end
```
