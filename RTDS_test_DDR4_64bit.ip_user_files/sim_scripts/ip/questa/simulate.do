onbreak {quit -f}
onerror {quit -f}

vsim -lib xil_defaultlib aurora_8b10b_1p25g_opt

do {wave.do}

view wave
view structure
view signals

do {aurora_8b10b_1p25g.udo}

run -all

quit -force
