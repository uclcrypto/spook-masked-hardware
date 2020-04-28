/*
    This module implements multiple dual sboxes corresponding to 
    the serialisation parameter chosen.
*/
(* fv_prop = "PINI", fv_strat = "flatten", fv_order=d *)
module MSKsbox_unit_dual
#
(
    parameter d = 2, // Number of masking shares
    parameter PDSBOX = 0,
    parameter Nbits = 128 // Number of state bits.
)
(cols, rnd1, rnd2, clk, inverse, cols_post_sb,enable);

// Generation params (DO NOT TOUCH)
localparam AM_BUND_cols = 2**PDSBOX; // Amount of column bundles
localparam SIZE_BUND_cols = d*Nbits/AM_BUND_cols; // Size of each column bundles
localparam AM_cols = 32/AM_BUND_cols; // Amount of column per column bundles

`include "spook_sbox_rnd.inc"

(* fv_type = "sharing", fv_latency = 0, fv_count=Nbits/AM_BUND_cols *)
input    [SIZE_BUND_cols-1:0]      cols;
(* fv_type = "random", fv_count=0 *) 
input [spook_sbox_rnd*32/(2**PDSBOX)/2-1:0] rnd1;
(* fv_type = "random", fv_count=0 *) 
input [spook_sbox_rnd*32/(2**PDSBOX)/2-1:0] rnd2;
(* fv_type = "clock" *) 
input clk;
(* fv_type = "sharing", fv_latency = 3, fv_count=Nbits/AM_BUND_cols *)
output    [SIZE_BUND_cols-1:0]      cols_post_sb;
input inverse;
input enable;

genvar i;
generate
for(i=0;i<AM_cols;i=i+1) begin: sb
    MSKspook_sbox_dual #(.d(d)) sbi (
        .in(cols[(i+1)*4*d-1:i*4*d]), 
        .rnd1(rnd1[i*spook_sbox_rnd/2 +: spook_sbox_rnd/2]),
        .rnd2(rnd2[i*spook_sbox_rnd/2 +: spook_sbox_rnd/2]),
        .clk(clk),
        .inverse(inverse),
        .out(cols_post_sb[(i+1)*4*d-1:i*4*d]),
        .enable(enable)
    );
end
endgenerate


endmodule
