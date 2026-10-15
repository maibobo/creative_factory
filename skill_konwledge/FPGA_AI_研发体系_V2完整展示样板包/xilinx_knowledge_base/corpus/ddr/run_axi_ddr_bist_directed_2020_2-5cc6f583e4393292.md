# run_axi_ddr_bist_directed_2020_2

- Category: `ddr`
- Source: `R:\DDR\axi_ddr4_min_2020_2\sim\run_axi_ddr_bist_directed_2020_2.tcl`
- SHA-256: `5cc6f583e43932923b708356e13d65d6a0ab2213fe34687bf4631f87a1f68df3`
- Extractor: `text`
- Tags: `ddr4, simulation`
- Duplicate sources:
  - E:\ddr_proc\staging_axi_ddr4_min_2020_2\sim\run_axi_ddr_bist_directed_2020_2.tcl

```tcl
set tb_scope  /tb_axi_ddr_bist
set dut_scope /tb_axi_ddr_bist/dut
set logged_object_count 0

# 记录DUT直属对象，不递归进入其他层次。
foreach object_handle [get_objects -quiet ${dut_scope}/*] {
    log_wave $object_handle
    incr logged_object_count
}

# Testbench只记录握手、Slave状态、注错控制和覆盖计数，不记录memory数组。
set tb_key_objects [list \
    ${tb_scope}/aclk \
    ${tb_scope}/aresetn \
    ${tb_scope}/start \
    ${tb_scope}/done \
    ${tb_scope}/pass \
    ${tb_scope}/fail \
    ${tb_scope}/error_count \
    ${tb_scope}/first_error_addr \
    ${tb_scope}/first_expected_data \
    ${tb_scope}/first_actual_data \
    ${tb_scope}/awaddr \
    ${tb_scope}/awvalid \
    ${tb_scope}/awready \
    ${tb_scope}/wdata \
    ${tb_scope}/wvalid \
    ${tb_scope}/wready \
    ${tb_scope}/bresp \
    ${tb_scope}/bvalid \
    ${tb_scope}/bready \
    ${tb_scope}/araddr \
    ${tb_scope}/arvalid \
    ${tb_scope}/arready \
    ${tb_scope}/rdata \
    ${tb_scope}/rresp \
    ${tb_scope}/rlast \
    ${tb_scope}/rvalid \
    ${tb_scope}/rready \
    ${tb_scope}/aw_pending \
    ${tb_scope}/w_pending \
    ${tb_scope}/awaddr_hold \
    ${tb_scope}/wdata_hold \
    ${tb_scope}/read_index_hold \
    ${tb_scope}/read_delay \
    ${tb_scope}/inject_bresp_error \
    ${tb_scope}/inject_read_data_error \
    ${tb_scope}/inject_rresp_error \
    ${tb_scope}/inject_rlast_error \
    ${tb_scope}/write_txn_count \
    ${tb_scope}/aw_first_count \
    ${tb_scope}/w_first_count \
    ${tb_scope}/same_cycle_count]

foreach object_path $tb_key_objects {
    set object_handle [get_objects -quiet $object_path]
    if {[llength $object_handle] > 0} {
        log_wave $object_handle
        incr logged_object_count
    } else {
        puts "DIRECTED_WAVE_OBJECT_NOT_FOUND=$object_path"
    }
}

puts "DIRECTED_WAVE_OBJECTS_TOTAL=$logged_object_count"
run all
quit
```
