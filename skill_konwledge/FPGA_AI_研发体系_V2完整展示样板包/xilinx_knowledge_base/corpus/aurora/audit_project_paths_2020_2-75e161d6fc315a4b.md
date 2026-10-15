# audit_project_paths_2020_2

- Category: `aurora`
- Source: `R:\aurora_64b66b_10p3125g_2020_2_verified\scripts\audit_project_paths_2020_2.tcl`
- SHA-256: `75e161d6fc315a4b582b038b3f656e42a47d3870514ae5e0dbaac3da082fe5e5`
- Extractor: `text`
- Tags: `1.25g, 10.3125g, 64b66b, 8b10b, aurora, verified, vivado-2020.2`
- Duplicate sources:
  - R:\aurora_8b10b_1p25g_2020_2_verified\scripts\audit_project_paths_2020_2.tcl

```tcl
if {$argc != 3} { error "usage: <project.xpr> <archive-root> <report.txt>" }
set xpr [file normalize [lindex $argv 0]]
set root [string tolower [file normalize [lindex $argv 1]]]
set report [file normalize [lindex $argv 2]]
open_project $xpr
set fp [open $report w]
puts $fp "Project=$xpr"
puts $fp "Part=[get_property PART [current_project]]"
puts $fp "Top=[get_property TOP [get_filesets sources_1]]"
set outside 0
foreach f [lsort [get_files -all]] {
  set normalized [string tolower [file normalize $f]]
  set in_archive [string match "${root}/*" $normalized]
  puts $fp "IN_ARCHIVE=$in_archive FILE=$f"
  if {!$in_archive} { incr outside }
}
puts $fp "OUTSIDE_FILE_COUNT=$outside"
close $fp
close_project
if {$outside != 0} { exit 4 }
exit 0
```
