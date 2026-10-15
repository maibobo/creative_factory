# collect_regression_summary

- Category: `cross_ip`
- Source: `R:\nvme_adc_axi_pipeline\scripts\collect_regression_summary.ps1`
- SHA-256: `812a855ee0bbde9934ad20b77d74028fe84ffa94e9c6e085f49bf4d41426a7ec`
- Extractor: `text`
- Tags: `nvme, pcie, tcl, verification`
- Duplicate sources:
  - none

```powershell
# 汇总已有XSim日志，不启动Vivado。
# PASS依据是日志中存在TEST_PASS；同时提取第一条以“Fatal:”开头的记录，
# 便于批处理失败后无需先打开完整日志即可定位首个终止原因。
$ErrorActionPreference = 'Stop'

$root = Split-Path $PSScriptRoot
# 测试列表需与run_vivado_regression.ps1保持一致。
$tests = @(
    'tb_adc_channel_packer',
    'tb_nvme_adc_pipeline',
    'tb_nvme_scheduler_errors'
)

# 每项记录结果、首个Fatal、绝对日志路径和日志最后更新时间。
$summary = foreach ($test in $tests) {
    $log = Join-Path $root `
        "build\regression\$test\${test}_project.sim\sim_1\behav\xsim\simulate.log"
    $passed = (Test-Path $log) -and
              (Select-String -LiteralPath $log -SimpleMatch 'TEST_PASS' -Quiet)
    $fatal = if (Test-Path $log) {
        Select-String -LiteralPath $log -Pattern '^Fatal:' |
            Select-Object -First 1 -ExpandProperty Line
    }
    [pscustomobject]@{
        Test = $test
        Result = if ($passed) { 'PASS' } else { 'FAIL' }
        FirstFatal = $fatal
        Log = $log
        Updated = if (Test-Path $log) {
            (Get-Item -LiteralPath $log).LastWriteTime.ToString('s')
        } else {
            $null
        }
    }
}

# 即使日志缺失也创建汇总目录并写summary.json；缺失日志按FAIL处理。
$outDir = Join-Path $root 'build\regression'
New-Item -ItemType Directory -Force -Path $outDir | Out-Null
$summary | ConvertTo-Json | Set-Content -Encoding UTF8 `
    (Join-Path $outDir 'summary.json')
$summary | Format-Table -AutoSize

# 为上层CI或PowerShell调用者提供可判定的失败退出码。
if ($summary.Result -contains 'FAIL') {
    exit 1
}
```
