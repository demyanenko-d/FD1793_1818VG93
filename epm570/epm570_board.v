// The EPM570T100 board: bdi_top (VG93 + Beta Disk glue + drive glue) with a PC 3.5" drive wired straight to the
// device, the drive connector as XP3 of the Pentagon 1024zp BDI (all drive signals active low):
//   pin 10 /SELECT0, 12 /SELECT1, 14 /SELECT2 (unused), 16 /START (the common motor, = HLD), 18 /DIR, 20 /STEP,
//   22 /WDATA, 24 /WGATE, 32 /SIDE1; inputs 8 /INDEX, 26 /TRK00, 28 /WPT, 30 /RDATA (34 /DSKCHG unused).
// A PC drive jumpered as B (factory setting: DS1 = pin 12, MOTEB = pin 16) is drive 1 of TR-DOS, as on the
// Pentagon. SYSCLK: the 50 MHz oscillator. The pin numbers are in epm570.qsf.
module epm570_board (
    input  wire SYSCLK,
    input  wire RESET_n,
    input  wire A1,
    input  wire [15:5] A,
    inout  wire [7:0] D,
    input  wire IORQ_n, MREQ_n, RD_n, WR_n, M1_n,
    input  wire DOS_BOOT, DOS_DIS,
    output wire DOS_n,
    // drive connector (active low)
    output wire DENSEL_n, SELECT0_n, SELECT1_n, SELECT2_n, START_n, DIR_n, STEP_n, WDATA_n, WGATE_n, SIDE1_n,
    input  wire INDEX_n, TRK00_n, WPT_n, RDATA_n, DSKCHG_n
);
    wire step, dirc, wg, hld, side1, ds0, ds1;
    bdi_top bdi (
        .SYSCLK(SYSCLK), .RESET_n(RESET_n), .A1(A1), .A(A), .D(D), .IORQ_n(IORQ_n), .MREQ_n(MREQ_n), .RD_n(RD_n),
        .WR_n(WR_n), .M1_n(M1_n), .DOS_BOOT(DOS_BOOT), .DOS_DIS(DOS_DIS), .DOS_n(DOS_n),
        .STEP(step), .DIRC(dirc), .WG(wg), .HLD(hld), .SIDE1(side1), .DS0(ds0), .DS1(ds1),
        .WDATA_n(WDATA_n), .RDATA_n(RDATA_n), .TR00_n(TRK00_n), .IP_n(INDEX_n), .WPRT_n(WPT_n));
    // bdi_top registers these (logical levels, 1 = active): only inverted here
    assign DENSEL_n  = 1'b1;
    assign SELECT0_n = !ds0;
    assign SELECT1_n = !ds1;
    assign SELECT2_n = 1'b1;
    assign START_n   = !hld;
    assign DIR_n     = !dirc;
    assign STEP_n    = !step;
    assign WGATE_n   = !wg;
    assign SIDE1_n   = !side1;
endmodule
