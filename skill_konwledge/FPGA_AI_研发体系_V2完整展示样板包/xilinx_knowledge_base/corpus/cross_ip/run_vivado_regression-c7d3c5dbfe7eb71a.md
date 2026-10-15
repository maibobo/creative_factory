# run_vivado_regression

- Category: `cross_ip`
- Source: `E:\NVME_PRO\nvme_adc_axi_pipeline\scripts\run_vivado_regression.ps1`
- SHA-256: `c7d3c5dbfe7eb71afc08ffb940ad21e09a5d6a3ce7bed8b1dddc046568c15dcb`
- Extractor: `text`
- Tags: `nvme, pcie, verification`
- Duplicate sources:
  - none

```powershell
# 五项行为回归的批处理入口。
# 本脚本只运行XSim，不运行OOC综合；每项必须同时满足Vivado退出码为0且
# simulate.log含TEST_PASS标记，随后再生成统一summary.json。
$ErrorActionPreference = 'Stop'

# 按项目约定固定使用本机Vivado 2020.2，不依赖PATH中的其他版本。
$vivado = 'D:\Xilinx_2020_2\Vivado\2020.2\bin\vivado.bat'
$script = Join-Path $PSScriptRoot 'run_vivado_test.tcl'
$tests = @(
    'tb_adc_channel_packer',
    'tb_nvme_adc_pipeline',
    'tb_nvme_scheduler_errors',
    'tb_nophae_dma_backend',
    'tb_nvme_adc_vitis_compat'
)

# 回归覆盖Packer边界、抽象系统闭环、调度错误、NoPHAE寄存器后端，
# 以及现有Vitis 0x9000_0000 ABI到ADC/DDR/NoPHAE的完整闭环。
$summary = @()
foreach ($test in $tests) {
    Write-Host "Running $test"
    & $vivado -mode batch -source $script -tclargs $test
    if ($LASTEXITCODE -ne 0) {
        throw "Vivado returned $LASTEXITCODE for $test"
    }

# XSim日志路径由run_vivado_test.tcl创建的工程名和默认behav运行目录决定。
    $log = Join-Path (Split-Path $PSScriptRoot) `
        "build\regression\$test\${test}_project.sim\sim_1\behav\xsim\simulate.log"
    $passed = (Test-Path $log) -and
              (Select-String -LiteralPath $log -SimpleMatch 'TEST_PASS' -Quiet)
    $summary += [pscustomobject]@{
        Test = $test
        Result = if ($passed) { 'PASS' } else { 'FAIL' }
        Log = $log
    }
    if (-not $passed) {
        throw "TEST_PASS marker missing for $test. See $log"
    }
}

# 二次扫描所有日志并输出机器可读JSON；任何FAIL使脚本返回非零。
& (Join-Path $PSScriptRoot 'collect_regression_summary.ps1')
if ($LASTEXITCODE -ne 0) {
    throw 'Regression summary contains a failed test.'
}
```
