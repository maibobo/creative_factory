# save_verification_entry_2020_2

- Category: `aurora`
- Source: `R:\aurora_64b66b_10p3125g_2020_2_verified\scripts\save_verification_entry_2020_2.tcl`
- SHA-256: `9f9d0c059dfe2657f25446b0a4ede28e11bc6cb9221b3477473510281ad00b92`
- Extractor: `text`
- Tags: `1.25g, 10.3125g, 64b66b, 8b10b, aurora, verified, vivado-2020.2`
- Duplicate sources:
  - R:\aurora_8b10b_1p25g_2020_2_verified\scripts\save_verification_entry_2020_2.tcl

```tcl
if {$argc != 3} {
  puts "ERROR: usage: <existing.xpr> <new_name> <verification_dir>"
  exit 2
}
set source_xpr [file normalize [lindex $argv 0]]
set new_name [lindex $argv 1]
set destination [file normalize [lindex $argv 2]]
open_project $source_xpr
save_project_as $new_name $destination -force
close_project
exit 0
```
