# check_hardware_2020_2

- Category: `ddr`
- Source: `R:\DDR\axi_ddr4_min_2020_2\tcl\check_hardware_2020_2.tcl`
- SHA-256: `2ca938105ad765a0937f918d0af864eb974486b884f01a91719af63809cda539`
- Extractor: `text`
- Tags: `ddr4, mig, tcl`
- Duplicate sources:
  - E:\ddr_proc\staging_axi_ddr4_min_2020_2\tcl\check_hardware_2020_2.tcl

```tcl
open_hw_manager

if {[catch {connect_hw_server -allow_non_jtag} connect_error]} {
    puts "HW_SERVER_CONNECT_RESULT=FAIL"
    puts "HW_SERVER_CONNECT_ERROR=$connect_error"
    error "Cannot connect to the local hardware server"
}

set targets [get_hw_targets -quiet]
puts "HW_TARGET_COUNT=[llength $targets]"
foreach target $targets {
    puts "HW_TARGET=$target"
}

if {[llength $targets] == 0} {
    puts "HW_DISCOVERY_RESULT=NO_TARGET"
    close_hw_manager
    error "No JTAG target is visible"
}

set ku040_count 0
foreach target $targets {
    if {[catch {open_hw_target $target} open_error]} {
        puts "HW_TARGET_OPEN_ERROR=$target:$open_error"
        continue
    }
    foreach device [get_hw_devices -quiet *xcku040*] {
        incr ku040_count
        puts "HW_DEVICE=$device"
    }
    close_hw_target
}

puts "KU040_DEVICE_COUNT=$ku040_count"
close_hw_manager

if {$ku040_count == 0} {
    puts "HW_DISCOVERY_RESULT=NO_KU040"
    error "JTAG targets exist, but no xcku040 device was found"
}
puts "HW_DISCOVERY_RESULT=PASS"
```
