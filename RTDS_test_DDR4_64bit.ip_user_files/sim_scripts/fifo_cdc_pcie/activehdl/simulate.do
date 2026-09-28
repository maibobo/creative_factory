onbreak {quit -force}
onerror {quit -force}

asim +access +r +m+fifo_cdc_pcie -L xpm -L fifo_generator_v13_2_5 -L xil_defaultlib -L unisims_ver -L unimacro_ver -L secureip -O5 xil_defaultlib.fifo_cdc_pcie xil_defaultlib.glbl

do {wave.do}

view wave
view structure

do {fifo_cdc_pcie.udo}

run -all

endsim

quit -force
