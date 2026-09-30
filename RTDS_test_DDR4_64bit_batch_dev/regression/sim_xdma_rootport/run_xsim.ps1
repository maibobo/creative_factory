param(
    [switch]$SkipAudit,
    [switch]$SkipPrepare,
    [switch]$SkipCompile,
    [switch]$SkipElaborate,
    [string]$VivadoBin = "D:\Xilinx_2020_2\Vivado\2020.2\bin",
    [ValidateSet("off", "auto", "2", "3", "4")]
    [string]$XelabMt = "off",
    [ValidateSet("off", "typical", "line", "wave", "all")]
    [string]$XelabDebug = "typical",
    [ValidateSet("0", "1", "2", "3")]
    [string]$XelabOptimize = "2",
    [switch]$FastMode,
    [ValidateRange(100, 10000000)]
    [int]$XsimMaxDeltaId = 10000,
    [ValidateRange(1, 1440)]
    [int]$WallClockTimeoutMinutes = 90
)

$ErrorActionPreference = "Stop"

# =============================================================================
# 用途：Vivado 2020.2/XSim 主编排器，完成审计、准备、编译、展开、运行和日志门禁。
# 输入：Skip*、VivadoBin、xelab debug/O/mt、FastMode、delta/墙钟上限。
# 输出：work/export、各阶段日志、simulate.log、summary.json 和进程退出码。
# 逻辑阶段：路径/模式校验 → IP 审计 → fileset 导出 → compile → xelab → xsim
# → compare_logs；只有明确满足复用条件才允许跳过前置阶段。
# 失败定位：按最后一个“主命令 → 关键反馈”进入对应日志；不要用后续阶段掩盖
# audit/compile/elaborate 的首个错误。
# =============================================================================

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

# ---------- 语义段 0B：归档上一轮固定名称日志，防止误读旧结果 ----------
# compile/elaborate 期间新的 simulate.log 尚未创建。若保留上一轮固定名称文件，
# 的目录，再删除工作副本；本轮各工具随后重新生成同名日志。
$RunStartStamp = Get-Date -Format "yyyyMMdd_HHmmss"
$PreviousRunFiles = @(
    "xvlog.log", "xvhdl.log", "xelab.log", "simulate.log",
    "summary.json", "test_summary.json", "rtds_minimum.wdb",
    "rtds_minimum.wcfg", "final_wave_acceptance.json"
)
$ExistingRunFiles = @($PreviousRunFiles | Where-Object {
    Test-Path -LiteralPath (Join-Path $Logs $_)
})
if ($ExistingRunFiles.Count -gt 0) {
    $previousRunArchive = Join-Path $Logs "previous_$RunStartStamp"
    New-Item -ItemType Directory -Path $previousRunArchive -Force | Out-Null
    foreach ($name in $ExistingRunFiles) {
        $source = Join-Path $Logs $name
        Copy-Item -LiteralPath $source -Destination $previousRunArchive -Force
        Remove-Item -LiteralPath $source -Force
    }
    Write-Host "RTDS_LOG_ARCHIVE: $previousRunArchive"
}

function Invoke-Checked([string]$Program, [string[]]$Arguments) {
    & $Program @Arguments
    if ($LASTEXITCODE -ne 0) {
        throw "Command failed ($LASTEXITCODE): $Program $($Arguments -join ' ')"
    }
}

function Invoke-XsimWithWatchdog([string]$Program, [string[]]$Arguments, [int]$TimeoutMinutes) {
    # ---------- 语义段 0A：墙钟看门狗 ----------
    # HDL 时间看门狗依赖仿真时间能够前进；真正的 delta-cycle 事件风暴会让
    # HDL 时钟停住。因此这里再用操作系统墙钟独立兜底，并终止整个进程树。
    $processStart = Get-Date
    $process = Start-Process -FilePath $Program -ArgumentList $Arguments -PassThru -WindowStyle Hidden
    $deadline = [DateTime]::UtcNow.AddMinutes($TimeoutMinutes)
    while (-not $process.HasExited -and [DateTime]::UtcNow -lt $deadline) {
        Start-Sleep -Seconds 2
        $process.Refresh()
    }
    if (-not $process.HasExited) {
        $stamp = Get-Date -Format "yyyyMMdd_HHmmss"
        $timeoutArchive = Join-Path $Logs "timeout_$stamp"
        New-Item -ItemType Directory -Path $timeoutArchive -Force | Out-Null
        foreach ($name in @("simulate.log", "xelab.log", "xvlog.log", "xvhdl.log")) {
            $source = Join-Path $Logs $name
            if (Test-Path -LiteralPath $source) {
                Copy-Item -LiteralPath $source -Destination $timeoutArchive -Force
            }
        }
        # CREATE_BREAKAWAY_FROM_JOB 远端启动时，taskkill /T 曾返回“拒绝访问”，
        # 只结束 PowerShell wrapper，却把 xsim/xsimk 留在后台继续运行。先结束
        # 直接子进程，再按本次唯一 log 路径筛选同一轮模拟器进程并逐个终止。
        $allProcesses = @(Get-CimInstance Win32_Process -ErrorAction SilentlyContinue)
        $ownedProcessIds = @([int]$process.Id)
        do {
            $newChildren = @($allProcesses | Where-Object {
                $_.ParentProcessId -in $ownedProcessIds -and
                $_.ProcessId -notin $ownedProcessIds
            } | Select-Object -ExpandProperty ProcessId)
            $ownedProcessIds += $newChildren
        } while ($newChildren.Count -gt 0)
        $ownedProcessIds | Sort-Object -Descending | ForEach-Object {
            Stop-Process -Id $_ -Force -ErrorAction SilentlyContinue
        }
        $runMarker = (Join-Path $Logs "simulate.log")
        Get-CimInstance Win32_Process -ErrorAction SilentlyContinue |
            Where-Object {
                $_.Name -in @("xsim.exe", "xsimk.exe", "xelab.exe") -and
                $_.CreationDate -ge $processStart.AddSeconds(-5) -and
                $_.CommandLine -like "*$runMarker*"
            } |
            Sort-Object CreationDate -Descending |
            ForEach-Object {
                Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue
            }
        throw "XSim wall-clock timeout after $TimeoutMinutes minute(s); logs: $timeoutArchive"
    }
    if ($process.ExitCode -ne 0) {
        throw "XSim failed ($($process.ExitCode)): $Program $($Arguments -join ' ')"
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
    # ---------- 语义段 3A：展开优化、调试可见性与多线程编译 ----------
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

    # 快速模式不保留内部波形可见性，换取更小的运行时开销；问题定位模式
    # 仍使用调用者选择的 debug 等级与完整 waves.tcl。
    $effectiveXelabDebug = if ($FastMode) { "off" } else { $XelabDebug }
    $effectiveXelabOptimize = if ($FastMode) { "3" } else { $XelabOptimize }

    $xelabDebugIndex = -1
    for ($argumentIndex = 0; $argumentIndex -lt $xelabArgs.Count; $argumentIndex++) {
        if ($xelabArgs[$argumentIndex] -eq "--debug") {
            $xelabDebugIndex = $argumentIndex
            break
        }
    }
    if ($xelabDebugIndex -ge 0) {
        $xelabArgs[$xelabDebugIndex + 1] = $effectiveXelabDebug
    } else {
        $xelabArgs += @("--debug", $effectiveXelabDebug)
    }

    # xelab -O3 会增加一次展开时间，但适合当前“单个完整 PCIe 用例运行很久”
    # 的场景。若复用 snapshot，此成本只在 RTL/参数变化时支付一次。
    $xelabArgs = @($xelabArgs | Where-Object { $_ -notmatch '^--?O[0-3]$' })
    # Vivado 2020.2 的实际 xelab 帮助使用 --O0/--O1/--O2/--O3，
    # 不是新版文档中也能见到的“-O 3”两参数写法。
    $xelabArgs += "--O$effectiveXelabOptimize"

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
    # 传给 XSim Tcl 层的 Windows 路径必须换成正斜杠，否则
    # `\r`/`\t` 会被 2020.2 当作转义字符，破坏 regression/scripts 路径。
    $runTclName = if ($FastMode) { "run_fast.tcl" } else { "run.tcl" }
    $runTclXsim = (Join-Path $Scripts $runTclName).Replace('\', '/')
    $wdbXsim = $wdb.Replace('\', '/')
    $simLogXsim = (Join-Path $Logs "simulate.log").Replace('\', '/')
    $xsimArgs = @(
        "board",
        "-tclbatch", $runTclXsim,
        "-maxdeltaid", $XsimMaxDeltaId,
        "-log", $simLogXsim
    )
    if (-not $FastMode) {
        $xsimArgs += @("-wdb", $wdbXsim)
    }
    Invoke-XsimWithWatchdog $Xsim $xsimArgs $WallClockTimeoutMinutes
} finally {
    Pop-Location
}

# ---------- 语义段 4：生成机器可读摘要并执行语义日志验收 ----------
& (Join-Path $Scripts "compare_logs.ps1") -SimulationLog (Join-Path $Logs "simulate.log")
exit $LASTEXITCODE
