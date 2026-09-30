onbreak {quit -f}
onerror {quit -f}

vsim -lib xil_defaultlib sys_mon_opt

do {wave.do}

view wave
view structure
view signals

do {sys_mon.udo}

run -all

quit -force
