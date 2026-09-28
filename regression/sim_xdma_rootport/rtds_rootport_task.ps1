$ErrorActionPreference = "Stop"

# ---------- 语义段 1：计划任务短路径入口 ----------
# schtasks.exe 的 /TR 参数上限为 261 字符，因此远端把本文件复制到
# C:\project\RTDS\rtds_rootport_task.ps1。完整工程路径和参数保留在此处。
# 输入：固定远端 wrapper、Vivado 路径和 Wave/Fast 运行参数。
# 输出：透传 detached worker 的状态、日志和退出码。
# 失败定位：计划任务未进入本文件查部署/权限；进入后查 detached_status.json。
$wrapper = "C:\project\RTDS\pcie_07\RTDS_test-1ch\RTDS_test-1ch\regression\sim_xdma_rootport_remote_20260717\run_xsim_detached.ps1"

& $wrapper `
    -RebuildSnapshot `
    -VivadoBin "C:\Xilinx\Vivado\2020.2\bin" `
    -WallClockTimeoutMinutes 90

exit $LASTEXITCODE
