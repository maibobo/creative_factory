param([string[]]$Cases=@('period_100ms'),[string]$Run='new_cases_r1')
$ErrorActionPreference='Stop'
$Root='C:\project\RTDS\DDR\RTDS_test_DDR4_64bit_batch_dev'
$Bin='C:\Xilinx\Vivado\2020.2\bin'
$out=Join-Path $Root "verification_20261010\$Run"
New-Item -ItemType Directory -Force -Path $out | Out-Null
$results=New-Object System.Collections.Generic.List[object]
function Tool($name,$a,$log) {
  $ErrorActionPreference='Continue'
  & "$Bin\$name.bat" @a 2>&1 | Out-File $log -Encoding utf8
  $exitCode=$LASTEXITCODE
  $ErrorActionPreference='Stop'
  if($exitCode -ne 0){throw "$name exit=$exitCode log=$log"}
}
Push-Location $out
try {
  Tool xvlog @('-sv','-work','xpm',"$Bin\..\data\ip\xpm\xpm_cdc\hdl\xpm_cdc.sv","$Bin\..\data\ip\xpm\xpm_fifo\hdl\xpm_fifo.sv") 'compile_xpm.log'
  Tool xvlog @('-work','work',"$Bin\..\data\verilog\src\glbl.v") 'compile_glbl.log'
  $files=@((Get-ChildItem "$Root\rtl" -Filter '*.v' -File).FullName)
  $new="$Root\RTDS_test_DDR4_64bit.srcs\sources_1\new"
  $files+=@("$new\INFO_EXCH.v","$new\CONV_DMA.v","$new\pcie_fdma_aurora_brg_adapter.v","$Root\rtl\ddr4\rtds_ddr4_backend.sv","$Root\rtl\ddr4\rtds_axi_ram_model.sv","$Root\external_snapshot\fdma_aurora_brg\fdma_aurora_brg.srcs\sources_1 - loop_validate\new\fdma_aurora_brg_tx.v")
  $files+=@((Get-ChildItem "$Root\regression\batch_1g" -Filter '*_test_if.sv' -File).FullName)
  $files+=@((Get-ChildItem "$Root\regression\new_cases_20261010" -Filter '*.sv' -File).FullName)
  $manifest=@($files|ForEach-Object {[pscustomobject]@{path=$_;sha256=(Get-FileHash -LiteralPath $_ -Algorithm SHA256).Hash.ToLower()}})
  $manifest | ConvertTo-Json -Depth 4 | Set-Content 'source_hashes.json' -Encoding utf8
  Tool xvlog (@('-sv','-L','xpm','-work','work')+$files) 'compile_tests.log'
  foreach($case in $Cases) {
    $started=Get-Date
    $case | Set-Content 'running_case.txt'
    try {
      Tool xelab @('-debug','all','-O3','-mt','off','-L','xpm','-L','unisims_ver',"work.tb_$case",'work.glbl','-s',$case) "$case.elaborate.log"
      $tcl=@("set top /tb_$case",("open_vcd "+$case+'.vcd'))
      if($case -eq 'period_100ms') {
        $tcl+=@('set sigs [get_objects $top/*]','set sigs [lsearch -all -inline -not -exact $sigs $top/clk]','set sigs [concat $sigs [get_objects $top/bus/*]]','set sigs [lsearch -all -inline -not -exact $sigs $top/bus/clk]','log_wave $sigs','log_vcd $sigs')
      } else {$tcl+=@('log_wave -r $top/*','log_vcd [get_objects -r $top/*]')}
      $tcl+=@('run all','close_vcd','quit')
      $tcl | Set-Content "$case.tcl" -Encoding ascii
      Tool xsim @($case,'-wdb',"$case.wdb",'-tclbatch',"$case.tcl",'-onerror','quit','-onfinish','stop','-log',"$case.simulate.log") "$case.console.log"
      $text=Get-Content "$case.simulate.log" -Raw
      $passed=($text -match "TEST PASS tb_$case") -and ($text -notmatch '(?m)^\s*(Fatal:|Error:|ERROR:)|TEST FAIL')
      $results.Add([pscustomobject]@{case=$case;passed=$passed;started=$started.ToString('o');finished=(Get-Date).ToString('o');log="$case.simulate.log";wdb="$case.wdb";vcd="$case.vcd"})
    } catch {$results.Add([pscustomobject]@{case=$case;passed=$false;error=$_.Exception.Message;started=$started.ToString('o')})}
    @($results.ToArray()) | ConvertTo-Json -Depth 5 | Set-Content 'summary.json' -Encoding utf8
  }
  [pscustomobject]@{completed=$true;passed=(@($results|Where-Object{-not $_.passed}).Count -eq 0);finished=(Get-Date).ToString('o')} | ConvertTo-Json | Set-Content 'completion.json' -Encoding utf8
} catch {$_|Out-String|Set-Content 'worker_error.txt';[pscustomobject]@{completed=$false;error=$_.Exception.Message}|ConvertTo-Json|Set-Content 'completion.json'}
finally {Pop-Location}
