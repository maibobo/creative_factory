# Export the example design that matches the upgraded XDMA instance. The
# generated files are kept outside sources_1 and serve as the vendor Root-Port
# model/TPI backend for the full PCIe serial-link profile.
set script_dir   [file dirname [file normalize [info script]]]
set project_path [file normalize [file join $script_dir .. RTDS_test.xpr]]
set output_dir   [file normalize [file join $script_dir vendor_models xdma_example]]

open_project $project_path
set xdma_ip [get_ips -quiet design_1_xdma_0_0]
if {[llength $xdma_ip] != 1} {
  error "Expected the BD XDMA IP object design_1_xdma_0_0"
}

file mkdir [file dirname $output_dir]
open_example_project -force -dir $output_dir $xdma_ip
puts "RTDS_XDMA_EXAMPLE_EXPORTED: $output_dir"
