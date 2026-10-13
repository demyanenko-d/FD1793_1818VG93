// Thanks to deathsoft for the transistor-level schematic of the chip and to titus for the gate-level RTL.
//
// MAX II build (rtl_epm570): replaces rtl/behav/vg93_ucode.vh (the Quartus SEARCH_PATH and the simulation
// +incdir list rtl_epm570/rtl first). The same program, re-encoded for a smaller decoder (sim/vg93-ucode.hex from
// docs/microcode/vg93-microcode-rom.hex, tools/recode): the tests at Cmd 30h..3Fh (Cmd[3:0] = the TEST_* code of
// vg93_actions.vh, OP7 at 3Fh), the stay select in hi and the skip select in imm of the control field words, the
// data path actions of the control field re-coded. Fields and names as in rtl/behav/vg93_ucode.vh.
//
//   bit  18..16  15..10  9..7  6..4  3..0
//         hi      cmd    mod    rw    imm
// hi and imm also form the inverted jump address {mod[0], hi, imm}; imm is the inverted counter preset.

localparam [5:0]
    CMD_SET_LOST        = 6'h00,
    CMD_READY_TST       = 6'h32,
    CMD_TR0_TST         = 6'h33,
    CMD_CLK_DROP        = 6'h03,
    CMD_TRK_ROL         = 6'h04,
    CMD_TRK_SH0         = 6'h06,
    CMD_TRK_SH1         = 6'h07,
    CMD_HLD_HLT_TST     = 6'h36,
    CMD_SET_BASE        = 6'h0A,
    CMD_SET_HLD         = 6'h0B,
    CMD_CLR_HLD_INT     = 6'h0C,
    CMD_CNT1_TST_INT    = 6'h29,
    CMD_CLR_HLD         = 6'h0E,
    CMD_RDATA_TST       = 6'h37,
    CMD_READ            = 6'h11,
    CMD_SEC_READ        = 6'h12,
    CMD_READ_AM         = 6'h13,
    CMD_DDEN_TST        = 6'h34,
    CMD_UPD_TG43        = 6'h15,
    CMD_STEP            = 6'h16,
    CMD_TRANS_AM        = 6'h17,
    CMD_A1_DET_CRC      = 6'h18,
    CMD_WR_DRQ_TST      = 6'h38,
    CMD_GOTO            = 6'h31,
    CMD_PREAM_STB_TST   = 6'h1B,
    CMD_WPRT_TST        = 6'h35,
    CMD_PREAM_INI_TST   = 6'h1D,
    CMD_CLR_RG          = 6'h1E,
    CMD_SET_RG          = 6'h1F,
    CMD_OP0             = 6'h20,  // OP0 .. OP6 = 20h .. 26h, OP7 = 3Fh (ucode_op_test)
    CMD_SET_BUSY        = 6'h28,
    CMD_ID_CNT_CALC     = 6'h39,
    CMD_SET_CRC_ERR     = 6'h3C,
    CMD_SET_REC_NOT_FND = 6'h2C,
    CMD_SET_WRT_ERR     = 6'h2D,
    CMD_SET_WRT_PRT     = 6'h2E,
    CMD_A1_DET          = 6'h2F,
    CMD_CLR_BUSY        = 6'h30,
    CMD_CRC_CLR         = 6'h01,
    CMD_SEC_ROL         = 6'h02,
    CMD_CLR_CRC_ERR     = 6'h05,
    CMD_CLR_DIRC        = 6'h08,
    CMD_UPD_DIRC        = 6'h09,
    CMD_SET_DIRC        = 6'h0D,
    CMD_CMP_MATCH       = 6'h3B,
    CMD_WRITE_STB_TST   = 6'h3A,
    CMD_WRITE           = 6'h0F,
    CMD_FORMAT          = 6'h10,
    CMD_CNT1_TST_DEC    = 6'h3E,
    CMD_CNT1_TST        = 6'h3D,
    CMD_CNT1_DEC        = 6'h14;

// ---- fields whose meaning depends on the encoding ----

// data path actions of a control field word (mod = 1x1): {cnt2_dec_on_byte, cnt2_dec_on_step, ser_inc,
// ser_inc_force_up, cmp_en}
localparam [4:0] CTL_CNT2_BYTE = 5'b10000, CTL_CNT2_STEP = 5'b01000, CTL_INC = 5'b00100, CTL_INC_UP = 5'b00010,
                 CTL_CMP = 5'b00001;
function [4:0] ucode_control(input [3:0] imm);
    case (imm)
    4'b0100, 4'b0101, 4'b0110, 4'b0111: ucode_control = CTL_CMP;   // compare with 0 / 1 / DATA_SHIFT[7] / RD_DATA
    4'b0000: ucode_control = CTL_CNT2_BYTE | CTL_INC;                // inc / dec by DIRC
    4'b0001: ucode_control = CTL_CNT2_STEP;                          // step rate delay
    4'b1100, 4'b1111: ucode_control = CTL_CNT2_BYTE;                 // CNT2 bytes (1111: also SKIP_PREAMBLE)
    4'b0010: ucode_control = CTL_CNT2_BYTE | CTL_INC | CTL_INC_UP;   // increment up
    default: ucode_control = 5'b00000;
    endcase
endfunction

// what a control field word waits for (STAY_*): hi
function [2:0] ucode_stay(input [2:0] hi, input [3:0] imm);
    case (hi)
    3'd0:    ucode_stay = STAY_PREAMBLE;
    3'd1:    ucode_stay = STAY_UNTIL_INDEX;
    3'd2:    ucode_stay = STAY_CNT1;
    3'd3:    ucode_stay = STAY_CNT2;
    3'd4:    ucode_stay = STAY_UNTIL_BYTE;
    3'd5:    ucode_stay = STAY_BYTE_CNT2;
    default: ucode_stay = STAY_NONE;
    endcase
endfunction

// when a word skips the next one (SKIP_*): imm = 1xSS of a control field word
function [1:0] ucode_skip(input [5:0] cmd, input [3:0] imm, input control);
    if (!control || !imm[3]) ucode_skip = SKIP_NONE;
    else
        case (imm[1:0])
        2'd1:    ucode_skip = SKIP_NEW_CMD;
        2'd2:    ucode_skip = SKIP_PREAMBLE_BYTE;
        2'd3:    ucode_skip = SKIP_PREAMBLE;
        default: ucode_skip = SKIP_NONE;
        endcase
endfunction

// OP0 .. OP6 at 20h..26h, OP7 at 3Fh (test bit cmd[2:0] of the command register): their codes as casez items of the
// decoder's command table
`define VG93_CMD_OP_ITEMS 6'b1000??, 6'b10010?, 6'b100110, 6'b111111
