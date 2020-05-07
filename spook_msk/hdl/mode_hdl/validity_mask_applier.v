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
    This module apply a 'validity' mask over bytes of the data
    provided at its input. 
*/
module validity_mask_applier
#
(
    parameter BUS_SIZE = 32
)
(
    data_in,
    data_in_validity,
    data_out
);

// Generation params 
localparam BUSdiv8 = BUS_SIZE/8;

// IOs ports 
input [BUS_SIZE-1:0] data_in;
input [BUSdiv8-1:0] data_in_validity;
output [BUS_SIZE-1:0] data_out;


genvar i;
generate
for(i=0;i<BUSdiv8;i=i+1) begin: mask
    assign data_out[(i+1)*8-1:i*8] = data_in[(i+1)*8-1:i*8] & {8{data_in_validity[i]}};
end
endgenerate


endmodule
