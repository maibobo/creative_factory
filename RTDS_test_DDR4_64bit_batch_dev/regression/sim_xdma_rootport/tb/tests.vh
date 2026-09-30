// 官方 pci_exp_usrapp_tx.v 在完成链路、枚举、BAR 初始化和 XDMA BAR 搜索后
// Windows 2020.2 的 xsim loader 无法可靠传递 TESTNAME=...；官方 AXI-MM
// 默认名是 dma_test0。本隔离 harness 不承载官方 dma_test0，因此在自定义
// 输入：官方 tx_usrapp 已完成枚举/BAR 搜索后的 testname。
// testname；若已进入用例，后续失败不归本兼容分支。
// ---------- 语义段 1：TESTNAME 兼容映射与唯一用例入口 ----------
else if ((testname == "rtds_minimum") || (testname == "dma_test0")) begin
    if (testname == "dma_test0") begin
        testname = "rtds_minimum";
        $display("RTDS_TEST_SELECT_DEFAULT: dma_test0 -> rtds_minimum (isolated harness)");
    end
    board.run_rtds_minimum;
end
