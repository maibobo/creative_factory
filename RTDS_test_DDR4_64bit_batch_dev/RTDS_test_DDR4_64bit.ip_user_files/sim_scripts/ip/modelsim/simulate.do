onbreak {quit -f}
onerror {quit -f}

vsim -voptargs="+acc" -L xilinx_vip -L xpm -L gtwizard_ultrascale_v1_7_9 -L xil_defaultlib -L unisims_ver -L unimacro_ver -L secureip -lib xil_defaultlib xil_defaultlib.aurora_8b10b_1p25g xil_defaultlib.glbl

do {wave.do}

view wave
view structure
view signals

do {aurora_8b10b_1p25g.udo}

run -all

quit -force
