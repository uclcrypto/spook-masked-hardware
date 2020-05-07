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
    This module is used to properly process the digested
    data during a decryption process.
*/
module decrypt_dig_blck_formatter
#(
    parameter BLCK_SIZE = 256
)
(
    dig_blck_in,
    dig_blck_in_validity,
    feed_blck_in,
    dec_dig_blck_out   
);

// Generation param //
localparam BLCKdiv8 = BLCK_SIZE/8;

// IOs ports 
input [BLCK_SIZE-1:0] dig_blck_in;
input [BLCKdiv8-1:0] dig_blck_in_validity;
input [BLCK_SIZE-1:0] feed_blck_in;
output [BLCK_SIZE-1:0] dec_dig_blck_out;


genvar i;
generate
for(i=0;i<BLCKdiv8;i=i+1) begin: mux
    assign dec_dig_blck_out[i*8 +: 8] = dig_blck_in_validity[i] ? dig_blck_in[i*8 +: 8] : feed_blck_in[i*8 +: 8] ^ dig_blck_in[i*8 +: 8];
end
endgenerate


endmodule
