param(
    [string]$Root = 'C:\project\RTDS\DDR\RTDS_test_DDR4_64bit_batch_dev',
    [string]$VivadoBin = 'C:\Xilinx\Vivado\2020.2\bin',
    [string]$OutName = ('smoke_nowave_' + (Get-Date -Format 'yyyyMMdd_HHmmss')),
    [string[]]$Cases = @('sync','1g','tx','rx_fifo','ring','axi','axi_tail','regs'),
    [switch]$SkipModules,
    [switch]$HighAddress
)
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
$out = Join-Path $Root "verification_20261010\$OutName"
New-Item -ItemType Directory -Path $out -Force | Out-Null
$results = New-Object System.Collections.Generic.List[object]
$bridge = Join-Path $Root 'external_snapshot\fdma_aurora_brg\fdma_aurora_brg.srcs\sources_1 - loop_validate\new'
$rtl = Join-Path $Root 'RTDS_test_DDR4_64bit.srcs\sources_1\new'
$test = Join-Path $Root 'regression\batch_1g'
$xpm = Join-Path $VivadoBin '..\data\ip\xpm'
$runTcl = Join-Path $out 'run_nowave.tcl'
[IO.File]::WriteAllText($runTcl, "puts {SMOKE_NOWAVE assertions=on waves=off}`nrun all`nquit`n", [Text.Encoding]::ASCII)
function Save-Results {
    @($results.ToArray()) | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath (Join-Path $out 'summary.json') -Encoding UTF8
}
function Invoke-Tool([string]$name, [string[]]$toolArgs, [string]$log) {
    $oldPreference = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    & (Join-Path $VivadoBin "$name.bat") @toolArgs 2>&1 | Out-File -LiteralPath $log -Encoding UTF8
    $code = $LASTEXITCODE
    $ErrorActionPreference = $oldPreference
    if ($code -ne 0) { throw "$name failed exit=$code log=$log" }
}
function Compile-Xpm {
    Invoke-Tool 'xvlog' @('-sv','-work','xpm',"$xpm\xpm_cdc\hdl\xpm_cdc.sv","$xpm\xpm_fifo\hdl\xpm_fifo.sv") 'compile_xpm.log'
    Invoke-Tool 'xvlog' @('-work','work',(Join-Path $VivadoBin '..\data\verilog\src\glbl.v')) 'compile_glbl.log'
}
function Run-Case([string]$name,[string]$top,[string]$pass) {
    $started = Get-Date
    try {
        Invoke-Tool 'xelab' @('-debug','off','-O3','-mt','off','-L','xpm','-L','unisims_ver',"work.$top",'work.glbl','-s',$name) "$name.elaborate.log"
        Invoke-Tool 'xsim' @($name,'-tclbatch',$runTcl.Replace('\','/'),'-onerror','quit','-onfinish','quit','-log',"$name.simulate.log") "$name.console.log"
        $content = Get-Content -LiteralPath "$name.simulate.log" -Raw
        $passed = ($content -match $pass) -and ($content -notmatch '(?m)^\s*(Fatal:|Error:|ERROR:)|\bTEST FAIL\b|regression FAILED')
        $results.Add([pscustomobject]@{case=$name;top=$top;passed=$passed;started=$started.ToString('o');finished=(Get-Date).ToString('o');log=(Join-Path (Get-Location) "$name.simulate.log");pass_pattern=$pass})
    } catch {
        $results.Add([pscustomobject]@{case=$name;top=$top;passed=$false;error=$_.Exception.Message;started=$started.ToString('o');finished=(Get-Date).ToString('o')})
    }
    Save-Results
}
try {
    if (-not $SkipModules) {
    $work=Join-Path $out 'modules'
    New-Item -ItemType Directory -Path $work -Force | Out-Null
    Push-Location $work
    try {
        Compile-Xpm
        $files = @((Get-ChildItem -LiteralPath "$Root\rtl" -File -Filter '*.v').FullName)
        $files += @("$rtl\INFO_EXCH.v","$rtl\CONV_DMA.v","$rtl\pcie_fdma_aurora_brg_adapter.v","$bridge\fdma_aurora_brg_tx.v","$Root\rtl\ddr4\rtds_axi_ram_model.sv")
        $files += @((Get-ChildItem -LiteralPath $test -File -Filter '*_test_if.sv').FullName)
        $files += @((Get-ChildItem -LiteralPath $test -File -Filter 'tb_*.sv').FullName)
        $files += "$Root\regression\board_cdc_smoke_20260921\tb_board_cdc_smoke.sv"
        Invoke-Tool 'xvlog' (@('-sv','-L','xpm','-work','work')+$files) 'compile_modules.log'
        foreach ($case in $Cases) {
            Run-Case $case "tb_rtds_$case" "TEST PASS tb_rtds_$case"
        }
        Run-Case 'board_cdc' 'tb_board_cdc_smoke' 'TEST PASS|BOARD_CDC.*PASS'
    } finally { Pop-Location }
    }
    $profiles=@('base')
    if($HighAddress){$profiles+='highaddr'}
    foreach($profile in $profiles) {
        $work=Join-Path $out "fast_$profile"
        New-Item -ItemType Directory -Path $work -Force | Out-Null
        Push-Location $work
        try {
            Compile-Xpm
            $fast = Join-Path $Root 'regression\sim_xdma_trythrough'
            $files=@("$fast\rtds_test_pkg.sv","$bridge\fdma_aurora_brg_tx.v","$bridge\fdma_aurora_brg_rx.v","$rtl\pcie_fdma_aurora_brg_adapter.v")
            $files+=@((Get-ChildItem -LiteralPath "$Root\rtl" -File -Filter '*.v').FullName)
            $files+=@("$fast\xdma_rp_backend.sv","$fast\aurora_ll_peer_bfm.sv","$fast\rtds_scoreboard.sv","$fast\rtds_assertions.sv","$fast\tb_xdma_rtds_trythrough.sv")
            $args=@('-sv','-L','xpm','-i',$fast,'-work','work')
            if($profile -eq 'highaddr'){$args+=@('-d','RTDS_TEST_NONZERO_CARD_HI')}
            Invoke-Tool 'xvlog' ($args+$files) 'compile_fast.log'
            Run-Case "fast_$profile" 'tb_xdma_rtds_trythrough' 'RTDS_TRYTHROUGH_PASS'
        } catch {
            $results.Add([pscustomobject]@{case="fast_$profile";passed=$false;error=$_.Exception.Message})
            Save-Results
        } finally {Pop-Location}
    }
    $waves=@(Get-ChildItem -LiteralPath $out -Recurse -File | Where-Object {$_.Extension -in '.wdb','.vcd','.fsdb'})
    [pscustomobject]@{completed=$true;passed=(@($results | Where-Object {-not $_.passed}).Count -eq 0);case_count=$results.Count;wave_count=$waves.Count;waves=@($waves.FullName);finished=(Get-Date).ToString('o')} | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath (Join-Path $out 'completion.json') -Encoding UTF8
    if(@($results | Where-Object {-not $_.passed}).Count -ne 0){exit 1}
} catch {
    $_ | Out-String | Set-Content -LiteralPath (Join-Path $out 'worker_error.txt') -Encoding UTF8
    Save-Results
    [pscustomobject]@{completed=$false;error=$_.Exception.Message} | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $out 'completion.json') -Encoding UTF8
    exit 1
}
