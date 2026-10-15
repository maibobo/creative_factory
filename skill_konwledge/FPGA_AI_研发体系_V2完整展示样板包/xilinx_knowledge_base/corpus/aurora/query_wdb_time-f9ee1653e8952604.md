# query_wdb_time

- Category: `aurora`
- Source: `E:\aurora_proc\scripts\query_wdb_time.tcl`
- SHA-256: `f9ee1653e8952604b7f5ddd64e264f58baba2391987b771beac7be88f4fe95aa`
- Extractor: `text`
- Tags: `aurora, automation, tcl`
- Duplicate sources:
  - none

```tcl
puts "CURRENT_TIME=[current_time]"
puts "CURRENT_WAVE_CONFIG=[current_wave_config]"
if {[string length [current_wave_config]] > 0} {
    report_property [current_wave_config]
}
exit
```
