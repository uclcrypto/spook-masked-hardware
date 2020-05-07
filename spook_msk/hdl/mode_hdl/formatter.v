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
  Format the value with respect to the validity of the bytes.
  Concat the constant 01 and fill with zeros if needed
  Done in three steps: 
  1) generate the mask extracting the valid bytes in the word (validity_mask)
  2) generate the word including the constant at the right place (cnst_word)
  3) Add the value, the mask and the constant word
*/

 module formatter
 #
 (
     parameter SIZE = 16
 )
 (
     data_raw,
     data_validity,
     data_formatted
 );

 // Generation params 
 localparam SIZEdiv8 = SIZE/8;

input [SIZE-1:0] data_raw;
input [SIZEdiv8-1:0] data_validity;
output [SIZE-1:0] data_formatted;

 // Validity masks /////////
 wire  [SIZE-1:0] validity_mask;

 genvar i;
 generate
 for(i=0;i<SIZEdiv8;i=i+1) begin: v_mask
     assign validity_mask[(i+1)*8-1:i*8] = data_validity[i] ? {8{1'b1}} : {8{1'b0}};
 end
 endgenerate

 // Constant word //////////
 wire [SIZEdiv8-1:0] cnst_mux_ctrl;
 wire [SIZE-1:0] cnst_word;

 // Constant addition muxes control generation for each bytes
 generate 
 for(i=0;i<SIZEdiv8;i=i+1) begin: c_mux_ctrl
     if(i==0)
         assign cnst_mux_ctrl[i] = ~(|(data_validity));
     else
         assign cnst_mux_ctrl[i] = data_validity[i-1] & (~data_validity[i]);
 end
 endgenerate

 // Mask generation
 generate
 for(i=0;i<SIZEdiv8;i=i+1) begin: cnst_wo
     assign cnst_word[(i+1)*8-1:i*8] = cnst_mux_ctrl[i] ? 8'b00000001 : 8'b0;
 end
 endgenerate

 // Addition /////////
 assign data_formatted = (data_raw & validity_mask) ^ cnst_word;



 endmodule
