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
