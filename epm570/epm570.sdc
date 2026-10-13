create_clock -name sysclk -period 20 [get_ports SYSCLK]
# mword_sr (the UFM reader, vg93_urom) changes only while a word is read (>= 0.8 us before any word or cell end
# uses it): multicycle 2
set_multicycle_path -from [get_registers {*urom|mword_sr*}] -setup 2
set_multicycle_path -from [get_registers {*urom|mword_sr*}] -hold 1
