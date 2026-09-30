# 在开发工程内部归档无活动引用的旧工程族；不删除原工程或备份。
set root [file normalize [file join [file dirname [info script]] ..]]
if {[file tail $root] ne "RTDS_test_DDR4_64bit_batch_dev"} {error "Cleanup only supports the remote development directory"}
# 仅检查已保存XPR的活动File Path；不打开第二个Vivado工程会话。
set h [open [file join $root RTDS_test_DDR4_64bit.xpr] r];set project_xml [read $h];close $h
set active {}
foreach {whole path} [regexp -all -inline {<File Path="([^"]+)"} $project_xml] {
 lappend active [string map [list {$PPRDIR} $root {$PSRCDIR} [file join $root RTDS_test_DDR4_64bit.srcs]] $path]
}
set dest [file normalize [file join $root archive_legacy_20260914]]
file mkdir $dest
set log [open [file join $root reports legacy_cleanup.txt] w]
foreach name {RTDS_test.xpr RTDS_test.srcs RTDS_test.hw RTDS_test.ip_user_files v201_delta.zip v201_sources.zip} {
 set path [file normalize [file join $root $name]]
 if {[file dirname $path] ne $root} {error "Unsafe cleanup target: $path"}
 set used 0
 foreach f $active {
  set f [file normalize $f]
  if {$f eq $path || [string first "$path/" $f] == 0} {set used 1}
 }
 if {$used} {puts $log "RETAIN active dependency: $path"; continue}
 if {[file exists $path]} {
  if {[file exists [file join $dest $name]]} {error "Archive already exists: $name"}
  file rename $path [file join $dest $name]
  puts $log "ARCHIVED $path -> $dest/$name"
 }
}
puts $log "Historical scripts under tcl/ and regression/ may refer to the archived project; they are not V2.01 entry points."
close $log

