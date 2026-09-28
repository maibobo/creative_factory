onbreak {quit -f}
onerror {quit -f}

vsim -lib xil_defaultlib ila_temp_opt

do {wave.do}

view wave
view structure
view signals

do {ila_temp.udo}

run -all

quit -force
