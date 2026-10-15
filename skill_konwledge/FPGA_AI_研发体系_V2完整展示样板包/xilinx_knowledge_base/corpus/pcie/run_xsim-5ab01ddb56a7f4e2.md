# run_xsim

- Category: `pcie`
- Source: `R:\pcie_07\RTDS_test-1ch\RTDS_test-1ch\regression\sim_xdma_rootport\run_xsim.ps1`
- SHA-256: `5ab01ddb56a7f4e2aa568af4bb72d2bfe6d554cd873d404264a5a9f236620041`
- Extractor: `text`
- Tags: `pcie, root-port, verification, xdma`
- Duplicate sources:
  - none

```powershell
param(
    [switch]$SkipAudit,
    [switch]$SkipPrepare,
    [switch]$SkipCompile,
    [switch]$SkipElaborate,
    [string]$VivadoBin = "D:\Xilinx_2020_2\Vivado\2020.2\bin",
    [ValidateSet("off", "auto", "2", "3", "4")]
    [string]$XelabMt = "off",
    [ValidateSet("off", "typical", "line", "wave", "all")]
    [string]$XelabDebug = "typical"
)

$ErrorActionPreference = "Stop"
# ---------- 语义段 0：固定 2020.2，但允许本机/远端安装盘不同 ----------
# 本机默认 D:\Xilinx_2020_2；远端显式传
# -VivadoBin C:\Xilinx\Vivado\2020.2\bin。只替换工具根目录，版本仍锁定 2020.2。
$VivadoRoot = Split-Path -Parent $VivadoBin
$VivadoData = Join-Path $VivadoRoot "data"
$Vivado = Join-Path $VivadoBin "vivado.bat"
$Xvlog  = Join-Path $VivadoBin "xvlog.bat"
$Xvhdl  = Join-Path $VivadoBin "xvhdl.bat"
$Xelab  = Join-Path $VivadoBin "xelab.bat"
$Xsim   = Join-Path $VivadoBin "xsim.bat"
foreach ($requiredTool in @($Vivado, $Xvlog, $Xvhdl, $Xelab, $Xsim)) {
    if (-not (Test-Path -LiteralPath $requiredTool)) {
        throw "Vivado 2020.2 tool not found: $requiredTool"
    }
}

$Root    = $PSScriptRoot
$Scripts = Join-Path $Root "scripts"
$Logs    = Join-Path $Root "logs"
$Export  = Join-Path $Root "work\export"

New-Item -ItemType Directory -Path $Logs -Force | Out-Null
$env:XILINX_LOCAL_USER_DATA = "NO"

function Invoke-Checked([string]$Program, [string[]]$Arguments) {
    & $Program @Arguments
    if ($LASTEXITCODE -ne 0) {
        throw "Command failed ($LASTEXITCODE): $Program $($Arguments -join ' ')"
    }
}

# ---------- 语义段 1：用固定 Vivado 2020.2 审计工程并导出 XSim ----------
if (-not $SkipAudit) {
    Invoke-Checked $Vivado @(
        "-mode", "batch", "-nojournal",
        "-source", (Join-Path $Scripts "audit_and_prepare.tcl"),
        "-log", (Join-Path $Logs "audit_and_prepare.log")
    )
}
if (-not $SkipPrepare) {
    Invoke-Checked $Vivado @(
        "-mode", "batch", "-nojournal",
        "-source", (Join-Path $Scripts "prepare_rootport_sim.tcl"),
        "-log", (Join-Path $Logs "prepare_rootport_sim.log")
    )
}

$RunDir = Get-ChildItem -LiteralPath $Export -Recurse -Filter "board.sh" |
    Select-Object -First 1 -ExpandProperty DirectoryName
if (-not $RunDir) { throw "export_simulation board.sh was not found" }

Push-Location $RunDir
try {
    # ---------- 语义段 2：在 PowerShell 中复现导出脚本的库映射 ----------
    Copy-Item -LiteralPath (Join-Path $VivadoData "xsim\xsim.ini") -Destination ".\xsim.ini" -Force
    $projectFiles = @("vlog.prj", "vhdl.prj") | Where-Object { Test-Path $_ }
    $libraries = foreach ($projectFile in $projectFiles) {
        Get-Content $projectFile | Where-Object { $_ -match "^(verilog|sv|vhdl)\s+(\S+)" } |
            ForEach-Object { [regex]::Match($_, "^(verilog|sv|vhdl)\s+(\S+)").Groups[2].Value }
    }
    foreach ($library in ($libraries | Sort-Object -Unique)) {
        if (-not (Select-String -LiteralPath ".\xsim.ini" -Pattern "^$([regex]::Escape($library))=" -Quiet)) {
            Add-Content -LiteralPath ".\xsim.ini" -Value "$library=xsim.dir/$library"
        }
    }

    # ---------- 语义段 3：编译、展开和运行 rtds_minimum ----------
    if (-not $SkipCompile) {
        Invoke-Checked $Xvlog @(
            "--relax", "-d", "XILINX_SIMULATOR",
            "--include", (Join-Path $VivadoData "xilinx_vip\include"),
            "--include", (Join-Path $Root "tb"),
            "--include", (Join-Path $Root "vendor\xdma_rp_2020_2"),
            "-prj", "vlog.prj", "-log", (Join-Path $Logs "xvlog.log")
        )
        if ((Test-Path "vhdl.prj") -and (Get-Item "vhdl.prj").Length -gt 0) {
            Invoke-Checked $Xvhdl @("--relax", "-prj", "vhdl.prj", "-log", (Join-Path $Logs "xvhdl.log"))
        }
    }

    $launcher = Get-Content -LiteralPath ".\board.sh"
    $xelabLine = $launcher | Where-Object { $_ -match "^\s*xelab\s" } | Select-Object -First 1
    if (-not $xelabLine) { throw "xelab command was not found in board.sh" }
    $xelabArgs = [regex]::Matches($xelabLine.Trim(), '(?:"[^"]*"|\S+)') |
        ForEach-Object { $_.Value.Trim('"') }
    $xelabArgs = @($xelabArgs | Select-Object -Skip 1)
    # ---------- 语义段 3A：保留 typical debug，并允许规避 2020.2 多线程崩溃 ----------
    # `waves.tcl` 会精确 log 所需对象；强制 `--debug wave` 会让完整 XDMA/PCIe
    # 加密模型的静态展开耗时数十分钟，且不会增加本用例的语义覆盖。
    # 本机 `--mt auto` 曾在 native module 编译阶段触发 XSIM 43-3294，默认关闭
    # 多线程以换取稳定性；确认环境稳定后可显式传入 -XelabMt auto。
    $xelabMtIndex = -1
    for ($argumentIndex = 0; $argumentIndex -lt $xelabArgs.Count; $argumentIndex++) {
        if ($xelabArgs[$argumentIndex] -eq "--mt") {
            $xelabMtIndex = $argumentIndex
            break
        }
    }
    if ($xelabMtIndex -ge 0) {
        $xelabArgs[$xelabMtIndex + 1] = $XelabMt
    } else {
        $xelabArgs += @("--mt", $XelabMt)
    }

    $xelabDebugIndex = -1
    for ($argumentIndex = 0; $argumentIndex -lt $xelabArgs.Count; $argumentIndex++) {
        if ($xelabArgs[$argumentIndex] -eq "--debug") {
            $xelabDebugIndex = $argumentIndex
            break
        }
    }
    if ($xelabDebugIndex -ge 0) {
        $xelabArgs[$xelabDebugIndex + 1] = $XelabDebug
    } else {
        $xelabArgs += @("--debug", $XelabDebug)
    }

    $xelabLogIndex = -1
    for ($argumentIndex = 0; $argumentIndex -lt $xelabArgs.Count; $argumentIndex++) {
        if ($xelabArgs[$argumentIndex] -eq "-log") {
            $xelabLogIndex = $argumentIndex
            break
        }
    }
    if ($xelabLogIndex -ge 0) {
        $xelabArgs[$xelabLogIndex + 1] = (Join-Path $Logs "xelab.log")
    } else {
        $xelabArgs += @("-log", (Join-Path $Logs "xelab.log"))
    }
    if (-not $SkipElaborate) {
        Invoke-Checked $Xelab $xelabArgs
    }

    $wdb = Join-Path $Logs "rtds_minimum.wdb"
    # ---------- 语义段 3B：运行已展开的 snapshot ----------
    # 2020.2 Windows loader 对含等号 plusarg 的兼容处理集中在
    # scripts/select_rtds_minimum.tcl，运行入口不再传递易被拆分的参数。
    # 传给 XSim Tcl 层的 Windows 路径必须换成正斜杠，否则
    # `\r`/`\t` 会被 2020.2 当作转义字符，破坏 regression/scripts 路径。
    $runTclXsim = (Join-Path $Scripts "run.tcl").Replace('\', '/')
    $wdbXsim = $wdb.Replace('\', '/')
    $simLogXsim = (Join-Path $Logs "simulate.log").Replace('\', '/')
    Invoke-Checked $Xsim @(
        "board",
        "-tclbatch", $runTclXsim,
        "-wdb", $wdbXsim,
        "-log", $simLogXsim
    )
} finally {
    Pop-Location
}

# ---------- 语义段 4：生成机器可读摘要并执行语义日志验收 ----------
& (Join-Path $Scripts "compare_logs.ps1") -SimulationLog (Join-Path $Logs "simulate.log")
exit $LASTEXITCODE
```
