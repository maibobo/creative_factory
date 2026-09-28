onbreak {quit -f}
onerror {quit -f}

vsim -lib xil_defaultlib fifo_cdc_aurora_opt

do {wave.do}

view wave
view structure
view signals

do {fifo_cdc_aurora.udo}

run -all

quit -force
