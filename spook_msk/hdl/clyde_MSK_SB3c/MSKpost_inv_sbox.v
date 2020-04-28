/*
    This module is used to implement the inverse sbox operation
    based on the direct sbox operation (only used for Clyde decryption).
    It is a linear layer applied after the sbox. 
*/
(* fv_strat = "flatten" *)
module MSKpost_inv_sbox #(parameter d=4) (sin,pin,out);

`include "spook_sbox_rnd.inc"

input [d*spook_sbox_nbits-1:0] sin;
input [d*2-1:0] pin;
output [d*spook_sbox_nbits-1:0] out;

wire [d-1:0] px0, px1, sx0, sx1, sx2, sx3, sx0px0, sx2px1, sx3sx2px1, sx2px1px0;
assign sx0 = sin[0 +: d];
assign sx1 = sin[d +: d];
assign sx2 = sin[2*d +: d];
assign sx3 = sin[3*d +: d];
assign px0 = pin[0 +: d];
assign px1 = pin[d +: d];

MSKxor_par #(.d(d), .count(1))
msk_xor_post_inv0(
    .ina(sx0),
    .inb(px0),
    .out(sx0px0)
);

MSKxor_par #(.d(d), .count(1))
msk_xor_post_inv1(
    .ina(sx2),
    .inb(px1),
    .out(sx2px1)
);

MSKxor_par #(.d(d), .count(1))
msk_xor_post_inv2(
    .ina(sx3),
    .inb(sx2px1),
    .out(sx3sx2px1)
);

MSKxor_par #(.d(d), .count(1))
msk_xor_post_inv3(
    .ina(sx2px1),
    .inb(px0),
    .out(sx2px1px0)
);

assign out[0 +: d] = sx1;
assign out[d +: d] = sx3sx2px1;
assign out[2*d +: d] = sx2px1px0;
assign out[3*d +: d] = sx0px0;

endmodule
