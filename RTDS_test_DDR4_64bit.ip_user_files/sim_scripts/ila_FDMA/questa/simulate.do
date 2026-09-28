onbreak {quit -f}
onerror {quit -f}

vsim -lib xil_defaultlib ila_FDMA_opt

do {wave.do}

view wave
view structure
view signals

do {ila_FDMA.udo}

run -all

quit -force
