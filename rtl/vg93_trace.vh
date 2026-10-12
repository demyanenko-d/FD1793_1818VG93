// Thanks to deathsoft for the transistor-level schematic of the chip and to titus for the gate-level RTL.
//
// Microword trace port of the behavioural model, included in vg93_top in simulation with VG93_UTRACE. One line per
// word end (the power-on word is k = 0); the testbench samples 0.5 ns after utr_k changes, when every register has
// its value after the word end. The fields follow the trace contract of the project (docs/behav_contract.md,
// rtl/tb/utrace_if.vh; bit 0 = the first name of each list, schematic names in the comments); the declarations are
// repeated here so that rtl/behav needs nothing from outside. The trace reads the registers of the blocks by
// hierarchical names, so their ports carry only what the neighbours need.
reg  [31:0] utr_k = 32'hFFFFFFFF;     // microword index, first value 0 (power-on edge)
wire [7:0]  utr_pc, utr_op, utr_trk, utr_sec, utr_dat, utr_sh, utr_c1, utr_lfsr;
wire [18:0] utr_mw, utr_ct, utr_dp;
wire [15:0] utr_crc;
wire [3:0]  utr_c2;
wire [16:0] utr_am;
wire [13:0] utr_st;
wire [4:0]  utr_bs;
wire [27:0] utr_wr;
wire [7:0]  utr_hb;
wire [5:0]  utr_ck;

// The trace shows two counters as the schematic encodes them: the step rate counter as the LFSR state (9Fh ... 0 in
// 250 steps) and the bit counter as the stages of the byte strobe shift counter.
reg  [7:0] utr_lfsr_of [0:249];
integer utr_i;
reg  [7:0] utr_l;
initial begin
    utr_l = 8'h9F;
    for (utr_i = 0; utr_i < 250; utr_i = utr_i + 1) begin
        utr_lfsr_of[utr_i] = utr_l;
        utr_l = {utr_l[6] == utr_l[5], utr_l[5:1], utr_l[7], !utr_l[0]};
    end
end
function [3:0] utr_stages_of(input [2:0] n);
    case (n)
    3'd0: utr_stages_of = 4'b1111; 3'd1: utr_stages_of = 4'b0111; 3'd2: utr_stages_of = 4'b0011;
    3'd3: utr_stages_of = 4'b0001; 3'd4: utr_stages_of = 4'b0000; 3'd5: utr_stages_of = 4'b1000;
    3'd6: utr_stages_of = 4'b1100; default: utr_stages_of = 4'b1110;
    endcase
endfunction

always @(posedge SYSCLK) if (word_ends) utr_k <= utr_k + 1;

assign utr_pc   = pc;
assign utr_mw   = mword;
assign utr_op   = cmd_reg;
assign utr_trk  = track_seen;
assign utr_sec  = sector_seen;
assign utr_dat  = data_seen;
assign utr_sh   = data_channel.data_shift;
assign utr_crc  = crc.crc;
assign utr_c1   = counters.cnt1;
assign utr_c2   = counters.cnt2;
assign utr_lfsr = utr_lfsr_of[drive.step_count];
assign utr_am   = read_path.am_window;

// status and handshake (status.flags_seen: bits F_BUSY, F_CRC_ERROR, F_RNF, F_WRITE_FAULT, F_WRITE_PROT = 0..4)
assign utr_st[0]  = status.flags_seen[0];                     // BUSY
assign utr_st[1]  = status.flags_seen[1];                     // CRC_ERR
assign utr_st[2]  = status.flags_seen[2];                     // RNF
assign utr_st[3]  = lost_seen;                                // LOST
assign utr_st[4]  = status.flags_seen[3];                     // RT_WF (U766)
assign utr_st[5]  = status.flags_seen[4];                     // WPRT (U767)
assign utr_st[6]  = drq;                                      // DRQ (pin register)
assign utr_st[7]  = intrq;                                    // INTRQ (pin)
assign utr_st[8]  = status.no_intrq_live;                     // RS_INTRQ
assign utr_st[9]  = data_channel.drq_live;                    // RS_DRQ
assign utr_st[10] = data_channel.read_pend_live;              // RS_RDPEND
assign utr_st[11] = data_channel.read_pend;                   // RDPEND
assign utr_st[12] = write_ready;                              // WR_READY
assign utr_st[13] = data_channel.lost;                        // LOST_D (U484)

// drive control, sampled inputs
assign utr_ct[0]  = type1;                                    // TYPE1
assign utr_ct[1]  = hld_pin;                                  // HLD
assign utr_ct[2]  = rg_pin;                                   // RG
assign utr_ct[3]  = dirc;                                     // DIRC
assign utr_ct[4]  = step_out;                                 // STEP
assign utr_ct[5]  = tg43;                                     // TG43
assign utr_ct[6]  = wg;                                       // WG
assign utr_ct[7]  = vfoe_seen;                                // VFOE
assign utr_ct[8]  = mr_s;                                     // MR_S
assign utr_ct[9]  = mfm;                                      // DDEN_S
assign utr_ct[10] = sequencer.wf_s;                           // WF_S (pin 33 incl. own /VFOE)
assign utr_ct[11] = drive.hlt;                                // HLT_S
assign utr_ct[12] = ready_seen;                               // READY_S
assign utr_ct[13] = tr00_seen;                                // TR00_S
assign utr_ct[14] = ip_seen;                                  // IP_L (U702)
assign utr_ct[15] = drive.ip_sample;                          // IP_S (U1015)
assign utr_ct[16] = drive.ip_sample_d;                        // IP_D (U1016)
assign utr_ct[17] = ready;                                    // READY_D (U1027)
assign utr_ct[18] = drive.step_tick_skip;                     // PRE_DIV2 (U1266)

// read data path, mark detector, serial ALU
assign utr_dp[0]  = preamble;                                 // PREAMBLE (U545)
assign utr_dp[1]  = any_mark;                                 // AMP (~U615)
assign utr_dp[2]  = rd_data;                                  // RD_DATA (U522)
assign utr_dp[3]  = read_path.preamble_sample;                // PRE_S (U544)
assign utr_dp[4]  = read_path.mark_sample;                    // MK_S (U626)
assign utr_dp[5]  = read_path.mark_latch_n;                   // MK_L (U616)
assign utr_dp[6]  = !clock_cell;                              // CW (clock window)
assign utr_dp[7]  = read_path.dec_sample;                     // DEC_S (U579)
assign utr_dp[8]  = read_path.dec_data;                       // DEC_D (U516)
assign utr_dp[9]  = read_path.det_a1;                         // SEL_A1 (U566)
assign utr_dp[10] = read_path.det_fm_mark;                    // SEL_AM (U567)
assign utr_dp[11] = read_path.det_trans;                      // SEL_TRANS (U1240)
assign utr_dp[12] = read_path.det_read_am;                    // SEL_RDAM (U1241)
assign utr_dp[13] = counters.id_bit0;                         // ID0
assign utr_dp[14] = counters.id_bit1;                         // ID1
assign utr_dp[15] = task_regs.inc_carry;                      // CARRY
assign utr_dp[16] = cmp_differ;                               // CMP (U569)
assign utr_dp[17] = cmp_greater;                              // CMP_HI (U584)
assign utr_dp[18] = task_regs.cmp_en_d;                       // CMP_EN (U580)

// byte strobe generator: Q0..Q3 (U652 U651 U646 U653), SER_INC_D (U632)
assign utr_bs   = {counters.inc_run, utr_stages_of(counters.bit_count)};

// data writer pipeline
assign utr_wr[2:0]   = write_path.index_pipe;                 // U293 U294 U295
assign utr_wr[5:3]   = write_path.fm_mark_pipe;               // U299 U300 U301
assign utr_wr[8:6]   = write_path.mfm_mark_pipe;              // U305 U306 U307
assign utr_wr[9]     = write_path.mfm_clock_drop;             // U309
assign utr_wr[14:10] = write_path.clock_pipe;                 // U314 U315 CDAT0 CDAT1 CDAT2
assign utr_wr[18:15] = write_path.data_pipe;                  // DATA0..3
assign utr_wr[19]    = write_path.no_write_d;                 // U255
assign utr_wr[20]    = write_path.pre_wg;                     // PRE_WG
assign utr_wr[21]    = write_path.mfm_late;                   // U281
assign utr_wr[22]    = write_path.mfm_early;                  // U270
assign utr_wr[23]    = write_path.cell_half2;                 // WG_F2 (U260)
assign utr_wr[25:24] = write_path.fm_late;                    // U280 U277
assign utr_wr[27:26] = write_path.fm_early;                   // U274 U275

// host writes: capture flop and one-microword enable per register
assign utr_hb[0] = host_bus.data_capture;                     // DAT_C
assign utr_hb[1] = wr_data_en;                                // DAT_EN
assign utr_hb[2] = host_bus.cmd_capture;                      // CMD_C
assign utr_hb[3] = wr_cmd_en;                                 // CMD_EN
assign utr_hb[4] = host_bus.trk_capture;                      // TRK_C
assign utr_hb[5] = wr_trk_en;                                 // TRK_EN
assign utr_hb[6] = host_bus.sec_capture;                      // SEC_C
assign utr_hb[7] = wr_sec_en;                                 // SEC_EN

// clock generator and raw sampler
assign utr_ck[0] = timing.read_request;                       // RDM_REQ (U19)
assign utr_ck[1] = timing.rclk_since_mr;                      // U15
assign utr_ck[2] = timing.read_cells1;                        // U20
assign utr_ck[3] = timing.read_cells2;                        // U21
assign utr_ck[4] = read_path.raw_lat0;                        // LAT0 (U500)
assign utr_ck[5] = read_path.raw_lat1;                        // LAT1 (U511)
