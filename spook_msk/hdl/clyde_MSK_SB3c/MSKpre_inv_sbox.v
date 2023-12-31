/*
    Copyright 2020 UCLouvain

    Licensed under the Solderpad Hardware Licence, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

        https://solderpad.org/licenses/SHL-2.0/

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/
/*
    This module is used to implement the inverse sbox operation
    based on the direct sbox operation (only used for Clyde decryption).
    It is a linear layer applied before the sbox.
*/
(* fv_strat = "flatten" *)
module MSKpre_inv_sbox #(parameter d=4) (in,out);

`include "spook_sbox_rnd.inc"

input [d*spook_sbox_nbits-1:0] in;
output [d*spook_sbox_nbits-1:0] out;

wire [d-1:0] x0, x1, x2, x3, x02;
assign x0 = in[0 +: d];
assign x1 = in[d +: d];
assign x2 = in[2*d +: d];
assign x3 = in[3*d +: d];

MSKxor_par #(.d(d), .count(1))
msk_xor_pre_inv(
    .ina(x0),
    .inb(x2),
    .out(x02)
);

assign out[0 +: d] = x1;
assign out[d +: d] = x02;
assign out[2*d +: d] = x3;
assign out[3*d +: d] = x0;

endmodule
