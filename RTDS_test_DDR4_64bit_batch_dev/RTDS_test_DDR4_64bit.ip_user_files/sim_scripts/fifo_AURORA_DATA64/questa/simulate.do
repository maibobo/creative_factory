onbreak {quit -f}
onerror {quit -f}

vsim -lib xil_defaultlib fifo_AURORA_DATA64_opt

do {wave.do}

view wave
view structure
view signals

do {fifo_AURORA_DATA64.udo}

run -all

quit -force
