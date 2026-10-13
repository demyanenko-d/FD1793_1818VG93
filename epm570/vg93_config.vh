// Build configuration of the EPM570 board (MAX II, SYSCLK 50 MHz, Beta Disk): replaces rtl/behav/vg93_config.vh
// (found first through the SEARCH_PATH of quartus/build.sh). The macros are described in rtl/behav/vg93_top.v and
// rtl_epm570/rtl/bdi_top.v. The simulation scripts (sim/) compile the common default and set their own macros.
`ifndef VG93_CONFIG_VH
`define VG93_CONFIG_VH
`define VG93_MFM_ONLY                 // cuts: MFM only, no TEST_n, no RG, no pin 33
`define VG93_NO_TEST
`define VG93_NO_RG
`define VG93_NO_PIN33
`define VG93_FAST_SYSCLK              // SYSCLK 50 MHz: no /RAWREAD catcher, REG_DAL_IN from the pins
`define VG93_TURBO_STEP               // step rate (head settle / load delays) as with CLK 2 MHz, the core at 1 MHz
`define VG93_EMBEDDED                 // DRQ / INTRQ push-pull inside the device
`define BDI_SNOOP_7FFD                // ROM 48 from the snooped #7FFD write (the board has no ROM48 wire)
`endif
