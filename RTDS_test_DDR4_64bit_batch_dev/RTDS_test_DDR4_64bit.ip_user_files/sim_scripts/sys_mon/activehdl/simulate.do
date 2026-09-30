onbreak {quit -force}
onerror {quit -force}

asim +access +r +m+sys_mon -L xpm -L xil_defaultlib -L unisims_ver -L unimacro_ver -L secureip -O5 xil_defaultlib.sys_mon xil_defaultlib.glbl

do {wave.do}

view wave
view structure

do {sys_mon.udo}

run -all

endsim

quit -force
