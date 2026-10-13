// Minimal Beta Disk (BDI, Beta 128 / KAY style) glue around the VG93 model (EPM570: microcode in the UFM), with a
// floppy drive wired straight to the device (fdd_glue: data separator and write precompensation).
// Z80 side, address lines A1 and A15..A5 only (A0, A2..A4 not wired: partial decoding), ports only while DOS is
// active and M1 is high:
//   A1 = 1, A7 = 0  VG93 registers (A6..A5 = A1..A0 of the chip: #1F / #3F / #5F / #7F)
//   A1 = 1, A7 = 1  #FF: write the system register, read {INTRQ, DRQ, 6'h3F}
// Without A0 / A2..A4 every port with A1 = 1 decodes as one of them while DOS is active (#FE of the ULA aliases
// #FF until a0 is wired). DOS: set on an opcode fetch (M1 and MREQ) at #3Dxx with ROM 48 selected, cleared on an
// opcode fetch outside #0000..#3FFF; on reset it takes the state of DOS_BOOT (boot into TR-DOS or into BASIC).
// DOS_DIS (active high) blocks TR-DOS, e.g. next to a DivMMC: while it is high the DOS flag is held cleared (no
// entry at #3Dxx, DOS_n high, the ports #1F..#FF inactive); it overrides DOS_BOOT.
// DOS_n is the only paging output (low while TR-DOS is active; the entry fetch itself already counts): the host
// side (the DE1) pages the TR-DOS ROM with it.
// BDI_SNOOP_7FFD: ROM 48 from a snooped #7FFD write (IORQ, WR, A15 = 0, A1 = 0; bit 4, lock bit 5) instead of the
// ROM48 pin.
// System register: bits 1..0 drive (0 / 1: DS0 / DS1; 2, 3 select none), 2 /MR (0 = reset), 3 HLT, 4 side (0 =
// side 1).
// Build with VG93_EMBEDDED (push-pull DRQ / INTRQ inside the device) and the cuts of the MAX II build (quartus/
// build.sh): VG93_MFM_ONLY VG93_NO_TEST VG93_NO_RG VG93_NO_PIN33 VG93_FAST_SYSCLK.
// The drive outputs go through flip-flops: WD of the model is combinational (as on the chip), its glitches at the
// SYSCLK edges would be extra flux transitions for the drive (de1/rtl/de1_top.v does the same; /WDATA is
// registered in fdd_glue).
`include "vg93_config.vh"
// Drive wiring as the Pentagon 1024zp BDI: HLD of the VG93 is READY (pin 32), the common motor START/ and the
// enable of the drive select decoder; HLT (#FF bit 3) pulls /IP low through VD1 while 0.
module bdi_top (
    input  wire SYSCLK,               // 50 MHz (the UFM reader needs >= ~40 MHz, vg93_urom; fdd_glue counts at 50)
    input  wire RESET_n,
    input  wire A1,
    input  wire [15:5] A,
    inout  wire [7:0] D,
    input  wire IORQ_n, MREQ_n, RD_n, WR_n, M1_n,
`ifndef BDI_SNOOP_7FFD
    input  wire ROM48,                // 1 = ROM 48 paged (48K machine: tie high)
`endif
    input  wire DOS_BOOT,             // DOS state after reset: 1 = TR-DOS active (boot into TR-DOS), 0 = BASIC
    input  wire DOS_DIS,              // 1 = TR-DOS blocked: DOS held passive (overrides DOS_BOOT)
    output wire DOS_n,                // TR-DOS active, active low
    // drive (logical levels, 1 = active, registered; /WDATA and /RDATA at the drive's levels)
    output reg  STEP = 1'b0, DIRC = 1'b0, WG = 1'b0, HLD = 1'b0, SIDE1 = 1'b0,   // HLD = START/: the common motor
    output reg  DS0 = 1'b0, DS1 = 1'b0,   // drive select (drives 0, 1)
    output wire WDATA_n,              // write data to the drive (fdd_glue)
    input  wire RDATA_n,              // read data from the drive (fdd_glue)
    input  wire TR00_n, IP_n, WPRT_n
);
    // ---- CLK: 50 MHz / 50 = 1 MHz square wave ----
    reg [4:0] cdiv = 5'd0;
    reg clk1 = 1'b0;
    always @(posedge SYSCLK)
        if (cdiv == 5'd24) begin cdiv <= 5'd0; clk1 <= !clk1; end
        else cdiv <= cdiv + 5'd1;

    // ---- DOS flag and ROM 48 ----
    wire fetch = !M1_n && !MREQ_n;
`ifdef BDI_SNOOP_7FFD
    reg rom48 = 1'b0, lock = 1'b0;
    wire p7ffd_wr = !IORQ_n && !WR_n && M1_n && !A[15] && !A1 && !lock;
    always @(posedge SYSCLK)
        if (!RESET_n) {lock, rom48} <= 2'b00;
        else if (p7ffd_wr) {lock, rom48} <= D[5:4];
`else
    wire rom48 = ROM48;
`endif
    wire dos_entry = fetch && A[15:8] == 8'h3D && rom48 && !DOS_DIS;
    reg dos = 1'b0;
    always @(posedge SYSCLK)
        if (DOS_DIS) dos <= 1'b0;
        else if (!RESET_n) dos <= DOS_BOOT;
        else if (dos_entry) dos <= 1'b1;
        else if (fetch && A[15:14] != 2'b00) dos <= 1'b0;
    wire dos_on = dos || dos_entry;   // the entry fetch itself already reads TR-DOS
    assign DOS_n = !dos_on;

    // ---- ports ----
    wire io = !IORQ_n && M1_n && dos && A1;
    wire vg_port = io && !A[7], sys_port = io && A[7];
    reg [4:0] sysreg = 5'd0;          // 1..0 drive, 2 /MR, 3 HLT, 4 side (0 = side 1)
    always @(posedge SYSCLK)
        if (!RESET_n) sysreg <= 5'd0;
        else if (sys_port && !WR_n) sysreg <= D[4:0];

    wire drq, intrq, tg43, early, late, step, dirc, wg, wd, hld, rclk, rawread_n;
    vg93_top fdc (
        .SYSCLK(SYSCLK), .CLK(clk1), .MR_n(sysreg[2] && RESET_n),
        .CS_n(!vg_port), .RE_n(RD_n), .WE_n(WR_n), .A(A[6:5]), .DAL(D), .DRQ(drq), .INTRQ(intrq),
        .STEP(step), .DIRC(dirc), .EARLY(early), .LATE(late), .HLD(hld), .TG43(tg43), .WG(wg), .WD(wd),
        .RCLK(rclk), .RAWREAD_n(rawread_n), .READY(hld), .TR00_n(TR00_n), .IP_n(IP_n && sysreg[3]), .WPRT_n(WPRT_n),
        .HLT(sysreg[3]));
    assign D = (sys_port && !RD_n) ? {intrq, drq, 6'h3F} : 8'bz;

    // ---- drive ----
    fdd_glue glue (.clk(SYSCLK), .rdata_n(RDATA_n), .rclk(rclk), .rawread_n(rawread_n),
                   .wd(wd && wg), .early(early), .late(late), .tg43(tg43), .wdata_n(WDATA_n));
    always @(posedge SYSCLK) begin
        {STEP, DIRC, WG, HLD} <= {step, dirc, wg, hld};
        SIDE1 <= !sysreg[4];
        {DS1, DS0} <= {hld && sysreg[1:0] == 2'd1, hld && sysreg[1:0] == 2'd0};   // decoder enabled by HLD
    end
endmodule
