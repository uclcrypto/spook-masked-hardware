/*
    This module performs the digestion process 
    of the data in the Spook algorithm.
*/
module digestion_unit
#
(
    parameter Nbits = 128
)
(
    in_bundle_state,
    in_bundle_block,
    in_bundle_block_validity,
    ctrl_en_digestion,
    ctrl_dec_mode,
    out_bundle_state,
    out_bundle_block
);

// Generation params 
localparam Nbdiv8 = Nbits/8;

// IOs ports 
input [Nbits-1:0] in_bundle_state;
input [Nbits-1:0] in_bundle_block;
input [Nbdiv8-1:0] in_bundle_block_validity;
input ctrl_en_digestion;
input ctrl_dec_mode;
output [Nbits-1:0] out_bundle_state;
output [Nbits-1:0] out_bundle_block;

// Digestion xor //
assign out_bundle_block = in_bundle_state ^ in_bundle_block;

// Data transformation (for decryption only) //
wire [Nbits-1:0] formatted_bundle_state;
decrypt_dig_blck_formatter #(.BLCK_SIZE(Nbits))
dec_TR_unit(
    .dig_blck_in(in_bundle_block),
    .dig_blck_in_validity(in_bundle_block_validity),
    .feed_blck_in(in_bundle_state),
    .dec_dig_blck_out(formatted_bundle_state)
);

// Mode selection mux //
wire [Nbits-1:0] mode_dep_bundle = ctrl_dec_mode ? formatted_bundle_state : out_bundle_block; 

// Bypass mux //
assign out_bundle_state = ctrl_en_digestion ? mode_dep_bundle : in_bundle_state;

endmodule 
