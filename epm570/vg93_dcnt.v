// Thanks to deathsoft for the transistor-level schematic of the chip and to titus for the gate-level RTL.
//
// Down counter, MAX II build (rtl_epm570): replaces rtl/behav/vg93_dcnt.v (its simulation model; the simulation
// of the EPM570 build uses that plain version). The counter on the MAX II carry chain, one LE per bit (arithmetic
// mode, LAB-wide synchronous load):
//   ena && sload: q <= d;  ena && shift: q <= q << 1;  ena: q <= q - 1.
// zero = (q == 0), taken from the carry out of the chain (q + all-ones carries out unless q is 0); in a shift
// word the chain computes q + q and zero shows !q[W-1] instead (the users never test it then).
module vg93_dcnt #(parameter W = 8) (
    input  wire clk, ena, sload, shift,
    input  wire [W-1:0] d,
    output wire [W-1:0] q,
    output wire zero
);
    // cell i: a = q[i], b = shift, c = carry in.  sum: shift ? cin : !(a ^ cin);  carry: shift ? a : a | cin
    wire [W:0] c;
    assign c[0] = 1'b0;
    genvar i;
    generate for (i = 0; i < W; i = i + 1) begin : bit_
        maxii_lcell #(.operation_mode("arithmetic"), .synch_mode("on"), .register_cascade_mode("off"),
                      .sum_lutc_input("cin"), .lut_mask("E1BA"), .power_up("low"), .output_mode("reg_only"),
                      .cin_used(i > 0 ? "true" : "false"))
            lc (.clk(clk), .dataa(q[i]), .datab(shift), .datac(d[i]), .datad(1'b1), .aclr(1'b0), .aload(1'b0),
                  .sclr(1'b0), .sload(sload), .ena(ena), .cin(c[i]), .inverta(1'b0),
                  .regout(q[i]), .cout(c[i+1]));
    end endgenerate
    maxii_lcell #(.operation_mode("normal"), .sum_lutc_input("cin"), .lut_mask("0F0F"), .output_mode("comb_only"),
                  .cin_used("true"))
        zc (.dataa(1'b1), .datab(1'b1), .datac(1'b1), .datad(1'b1), .cin(c[W]), .combout(zero));
endmodule
