// Thanks to deathsoft for the transistor-level schematic of the chip and to titus for the gate-level RTL.
//
// Microcode store, MAX II build (rtl_epm570): replaces rtl/behav/vg93_urom.v. The re-encoded program
// (sim/vg93-ucode.hex, field codes in vg93_ucode.vh) is in the UFM (vg93_ufm, image vg93-ufm19.mif by
// tools/gen_ufm.py) and is read serially after the word end that selects it: no prefetch, the next address is
// known only at the word end. Nothing outside sees the new word before ~2 us into it except TYPE1 and read_enable,
// which vg93_decoder takes from PC / the last word while fetching. Needs SYSCLK >= ~40 MHz (50 MHz: UFM clock
// 25 MHz, a word in 1.2 us of a 4 us word). Simulation: sim/vg93_ufm_model.v replaces the atom (vg93_ufm).
//
// cyc counts SYSCLK cycles from the word end; step = cyc / 2 is one UFM clock: its controls are decoded from step,
// the clocks (registers) rise between the two cycles of a step, and drdout is sampled as the step ends. mword_sr is
// the address shift register first (ardin = its MSB, held inverted) and then the data shift register (drdout
// shifts in at its LSB): after the 19 data samples it holds the word. Layout: UFM word 2p = bits 18..3 of microword
// p, word 2p + 1 = bits 2..0 in its top bits.
//   step 0      the address (new PC) goes into mword_sr
//   1..9        address shift: PC (8 bits, MSB first), 0
//   10          load the first UFM word (drshft = 0)
//   11..25      shift it out (MSB first); step 11 also increments the address (arshft = 0)
//   26          load the second UFM word
//   27, 28      shift
//   29          done: the word is valid (60 SYSCLK cycles = 1.2 us at 50 MHz)
// The data bit is sampled as steps 10..28 end (19 bits). A word end that keeps PC (keep) does not read again.
module vg93_urom (
    input  wire sysclk,
    input  wire word_ends,
    input  wire [7:0] addr,               // address of the coming word (taken at word_ends)
    input  wire [7:0] pc,                 // address of the current word (the new PC from the cycle after the end)
    input  wire keep,                     // this word end keeps PC and the word: no read
    output wire [18:0] mword,             // the current microword (REG_MCMD, re-encoded); valid when !fetching
    output wire fetching                  // the word is being read from the UFM
);
    localparam [4:0] STEP_DONE = 5'd29;
    reg  [18:0] mword_sr = 19'd0;         // the word the power-on edge acts on, 0 as in rtl/behav (CNT1 = 0Fh)
    reg  [5:0] cyc = {STEP_DONE, 1'b0};   // the power-on edge starts the first read
    reg  arclk = 1'b0, drclk = 1'b0;
    wire [4:0] step = cyc[5:1];
    wire drdout;
    assign mword = mword_sr;
    assign fetching = step != STEP_DONE;
    wire ar_shft = step <= 5'd9;          // step 0 shifts a junk bit too (9 address bits follow)
    wire ar_clk_next = !cyc[0] && (ar_shft || step == 5'd11);
    wire dr_clk_next = !cyc[0] && !ar_shft && fetching;
    wire dr_shft = !(step == 5'd10 || step == 5'd26);
    vg93_ufm ufm (.arclk(arclk), .ardin(!mword_sr[18]), .arshft(ar_shft), .drclk(drclk), .drshft(dr_shft),
                  .drdout(drdout));

    always @(posedge sysclk) begin
        arclk <= ar_clk_next;
        drclk <= dr_clk_next;
        if (word_ends && !keep) cyc <= 6'd0;
        else if (fetching) begin
            cyc <= cyc + 6'd1;
            if (cyc[0]) mword_sr <= {mword_sr[17:0], drdout};   // [18:10] at step 0: the load below
        end
        if (step == 5'd0) mword_sr[18:10] <= ~{pc, 1'b0};   // the address (the new PC), inverted
    end
endmodule
