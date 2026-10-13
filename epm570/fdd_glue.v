// Floppy drive glue for a drive wired straight to the device (bdi_top): a digital data separator for the read side
// and the write precompensation for the write side. SYSCLK 50 MHz; both count at 25 MHz (every other SYSCLK, the
// clock enable ce): 40 ns steps, shorter counters.
// Credit: the DPLL algorithm after fapch_zek by ZEK (ZX-Evolution / TS-Config, github.com/tslabs/zx-evo,
// pentevo/fpga/current/vg93), the precompensation after the same vg93.v.
//
// Read: /RDATA is synchronised and filtered (a level must hold two samples), its falling edge is one flux
// transition: /RAWREAD (one 25 MHz step = 40 ns; the model samples it every SYSCLK, VG93_FAST_SYSCLK). RCLK is a free
// running square wave of 50 steps per half period (2 us: one MFM channel bit at 250 kbit/s); on every transition
// the phase counter is pulled half way to the window centre (cnt <= (cnt + 24) / 2), so the separator follows the
// speed of the disk.
// Write: a WD pulse of the model starts one counter loaded with delay + width; /WDATA is low (registered) while the
// counter is <= the width (6 steps = 240 ns). Delay 3 steps nominal; LATE / EARLY move it by 1 step (40 ns) outside
// TG43, by 2 steps (80 ns) inside.
module fdd_glue #(
    parameter CE_HALF = 1,           // 1: count every other clk (SYSCLK 50 MHz -> 25 MHz steps), 0: every clk
    parameter [5:0] HALF = 6'd50     // steps per RCLK half period (2 us): 50 at 25 MHz, 56 at 28 MHz (the DE1)
) (
    input  wire clk,                 // SYSCLK, the model's clock
    input  wire rdata_n,             // /RDATA from the drive
    output reg  rclk = 1'b0,         // to the model: RCLK
    output wire rawread_n,           // to the model: /RAWREAD
    input  wire wd, early, late, tg43,   // from the model (same clock)
    output reg  wdata_n = 1'b1       // /WDATA to the drive
);
    reg ce_t = 1'b0;                 // steps: every other clk (CE_HALF) or every clk
    always @(posedge clk) ce_t <= !ce_t;
    wire ce = CE_HALF ? ce_t : 1'b1;
    localparam [6:0] CENTRE = HALF / 2 - 1;
    // ---- separator ----
    reg [2:0] rs = 3'b111;           // input synchroniser
    reg rd = 1'b1, rd_d = 1'b1;      // filtered level
    always @(posedge clk) if (ce) begin
        rs <= {rs[1:0], rdata_n};
        if (rs[2:1] == 2'b00 || rs[2:1] == 2'b11) rd <= rs[2];
        rd_d <= rd;
    end
    wire pulse = rd_d && !rd;        // falling edge of /RDATA, one step
    assign rawread_n = !pulse;       // /RAWREAD: one step (2 SYSCLK)
    reg [5:0] cnt = 6'd0;            // phase in the RCLK half period, 0..HALF-1
    wire [6:0] pull = {1'b0, cnt} + CENTRE;  // cnt + (C - cnt) / 2 = (cnt + C) / 2: half way to the centre
    always @(posedge clk) if (ce) begin
        if (pulse) cnt <= pull[6:1];
        else if (cnt == HALF - 6'd1) begin cnt <= 6'd0; rclk <= !rclk; end
        else cnt <= cnt + 6'd1;
    end

    // ---- write precompensation: one counter, load = delay + width, /WDATA while counter <= width ----
    reg wd_d = 1'b0;                 // WD is a CLK-low window (>= 300 ns): seen at the 25 MHz steps
    always @(posedge clk) if (ce) wd_d <= wd;
    wire wd_start = wd && !wd_d;
    reg [3:0] pc = 4'd0;
    always @(posedge clk) if (ce) begin
        if (wd_start)
            case ({late, tg43, early})
            3'b110:  pc <= 4'd11;    // late, inner tracks: delay 5
            3'b100:  pc <= 4'd10;    // late: 4
            3'b011:  pc <= 4'd7;     // early, inner tracks: 1
            3'b001:  pc <= 4'd8;     // early: 2
            default: pc <= 4'd9;     // nominal: 3 steps delay + 6 steps pulse
            endcase
        else if (pc != 4'd0) pc <= pc - 4'd1;
        wdata_n <= !(pc != 4'd0 && pc <= 4'd6);
    end
endmodule
