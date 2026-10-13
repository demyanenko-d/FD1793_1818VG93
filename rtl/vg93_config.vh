// Build configuration of the model: the build macros of vg93_top.v set in code. This default sets none - the
// chip, identical at the pins and in the microword trace to the gate-level schematic. A variant supplies its own
// vg93_config.vh found first in the include path (rtl_epm570/rtl/vg93_config.vh: the EPM570 board); a macro may
// also come from the project or the command line (+define), as before. The list: vg93_top.v header.
`ifndef VG93_CONFIG_VH
`define VG93_CONFIG_VH
`endif
