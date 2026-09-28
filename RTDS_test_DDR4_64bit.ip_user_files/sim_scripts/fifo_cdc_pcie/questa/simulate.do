onbreak {quit -f}
onerror {quit -f}

vsim -lib xil_defaultlib fifo_cdc_pcie_opt

do {wave.do}

view wave
view structure
view signals

do {fifo_cdc_pcie.udo}

run -all

quit -force
