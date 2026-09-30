onbreak {quit -force}
onerror {quit -force}

asim +access +r +m+aurora_8b10b_1p25g -L xilinx_vip -L xpm -L gtwizard_ultrascale_v1_7_9 -L xil_defaultlib -L unisims_ver -L unimacro_ver -L secureip -O5 xil_defaultlib.aurora_8b10b_1p25g xil_defaultlib.glbl

do {wave.do}

view wave
view structure

do {aurora_8b10b_1p25g.udo}

run -all

endsim

quit -force
