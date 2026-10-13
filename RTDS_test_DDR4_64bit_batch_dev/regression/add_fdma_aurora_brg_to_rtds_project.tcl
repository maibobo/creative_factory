# Add the real fdma_aurora_brg adapter integration sources to RTDS_test.
# If the checkout location changes, edit only these three path variables.

set project_path {E:/PCIE-CPU/RTDS_test/RTDS_test.xpr}
set rtds_root    {E:/PCIE-CPU/RTDS_test/RTDS_test.srcs/sources_1/new}
set brg_root     {E:/PCIE-CPU/fdma_aurora_brg/fdma_aurora_brg.srcs/sources_1 - loop_validate/new}
set aurora_root  {E:/PCIE-CPU/fdma_aurora_brg/fdma_aurora_brg.srcs/sources_1 - loop_validate}
set aurora_ex    "$aurora_root/imports/aurora_64b66b_0_ex"
set sim_root     {E:/PCIE-CPU/RTDS_test/regression/sim_xdma_trythrough}

open_project $project_path

set design_files [list \
  "$brg_root/cdc_sync.v" \
  "$brg_root/fdma_aurora_brg_tx.v" \
  "$brg_root/fdma_aurora_brg_rx.v" \
  "$brg_root/fdma_aurora_brg_top.v" \
  "$rtds_root/pcie_fdma_aurora_brg_adapter.v" \
  "$aurora_ex/imports/aurora_64b66b_0_cdc_sync_exdes.v" \
  "$aurora_ex/imports/aurora_64b66b_0_example_ll_to_axi.v" \
  "$aurora_ex/imports/aurora_64b66b_0_example_axi_to_ll.v" \
  "$aurora_ex/imports/aurora_64b66b_0_exdes.v" \
  "$aurora_ex/aurora_64b66b_0_ex.srcs/sources_1/new/aurora_64b66b_top.v" \
]

foreach f $design_files {
  if {![file exists $f]} {
    error "Missing design source: $f"
  }
  if {[llength [get_files -quiet $f]] == 0} {
    add_files -norecurse -fileset sources_1 [list $f]
  }
}

set aurora_xci "$aurora_root/ip/aurora_64b66b_0/aurora_64b66b_0.xci"
if {![file exists $aurora_xci]} {
  error "Missing Aurora IP: $aurora_xci"
}
if {[llength [get_files -quiet $aurora_xci]] == 0} {
  add_files -norecurse -fileset sources_1 [list $aurora_xci]
}

set_property top TOP [get_filesets sources_1]
set_property xpm_libraries {XPM_CDC XPM_FIFO} [current_project]

set sim_files [list \
  "$sim_root/rtds_test_pkg.sv" \
  "$sim_root/xdma_rp_backend.sv" \
  "$sim_root/aurora_ll_peer_bfm.sv" \
  "$sim_root/rtds_scoreboard.sv" \
  "$sim_root/rtds_assertions.sv" \
  "$sim_root/tb_xdma_rtds_trythrough.sv" \
]
foreach f $sim_files {
  if {![file exists $f]} {
    error "Missing simulation source: $f"
  }
  if {[llength [get_files -quiet -of_objects [get_filesets sim_1] $f]] == 0} {
    add_files -norecurse -fileset sim_1 [list $f]
  }
}
set_property include_dirs [list $sim_root] [get_filesets sim_1]
set_property top tb_xdma_rtds_trythrough [get_filesets sim_1]

update_compile_order -fileset sources_1
update_compile_order -fileset sim_1
close_project
