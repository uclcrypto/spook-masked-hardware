/*
    This module performs the Round A (extended) of 
    the shadow primitive. 
    More specifically, the following operation are performed:
        -Sbox layer
        -Lbox layer
        -32-bits constant addition
        -Sbox layer
*/
module SLWS_unit
#
(
    parameter Nbits = 128,
    parameter BAmount = 4
)
(
    in_bundles_state,
    in_W32,
    out_bundles_state_SLWS
);

// SNbits - Shadow state bits - Amount of bits in shawdow state
localparam SNbits = BAmount * Nbits;

// IOs ports
input [SNbits-1:0] in_bundles_state;
input [31:0] in_W32;
output [SNbits-1:0] out_bundles_state_SLWS;

// Input representation transformation //
wire [Nbits-1:0] in_cols_state;
bundle2cols #(.d(1),.Nbits(Nbits))
b2c_state_in(
    .bundle_in(in_bundles_state[0 +: Nbits]),
    .cols(in_cols_state)
);

// SB unit //
wire [Nbits-1:0] cols_post_SB;
sbox_unit #(0) 
sbu(
    .cols(in_cols_state),
    .cols_post_sb(cols_post_SB)
);

// Data representation transformation //
wire [Nbits-1:0] bundle_post_SB;
cols2bundle #(.d(1),.Nbits(128)) 
c2b_SB(
    .cols(cols_post_SB),
    .bundle_out(bundle_post_SB)
);

// LB unit //
wire [Nbits-1:0] bundle_post_LB;
lbox_unit #(0) 
lbu(
    .bundle_in(bundle_post_SB),
    .bundle_out(bundle_post_LB)
);

// W32 addition //
// Only in Shadow mode: add W over row 1
wire [31:0] r1postW = bundle_post_LB[1*32 +: 32] ^ in_W32;

wire [Nbits-1:0] bundle_post_W32add = {
    bundle_post_LB[64 +: 64], 
    r1postW,
    bundle_post_LB[0 +: 32]
};

// Column representation
wire [Nbits-1:0] cols_post_W32add;
bundle2cols #(.d(1),.Nbits(Nbits))
b2c_4W(
    .bundle_in(bundle_post_W32add),
    .cols(cols_post_W32add)
);
 
// Last sbox unit //
wire [Nbits-1:0] cols_post_SB2;
sbox_unit #(0) 
sbu2(
    .cols(cols_post_W32add),
    .cols_post_sb(cols_post_SB2)
);


// Output data representation //
wire [Nbits-1:0] SLWS_processed_bundle;
cols2bundle #(.d(1),.Nbits(Nbits))
c2b_out_SLWS(
    .cols(cols_post_SB2),
    .bundle_out(SLWS_processed_bundle)
);

// REordering (applying the shift basically) //
assign out_bundles_state_SLWS[3*Nbits +: Nbits] = SLWS_processed_bundle;
assign out_bundles_state_SLWS[0 +: 3*Nbits] = in_bundles_state[Nbits +: 3*Nbits];

endmodule
