onbreak {quit -force}
onerror {quit -force}

asim +access +r +m+ila_temp -L xpm -L xil_defaultlib -L unisims_ver -L unimacro_ver -L secureip -O5 xil_defaultlib.ila_temp xil_defaultlib.glbl

do {wave.do}

view wave
view structure

do {ila_temp.udo}

run -all

endsim

quit -force
