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
    This module is used to modify the bit order of the sharing. The only reason 
    to perform this modification is because the sharing representation differs
    between the SW interface and the HW. 
*/
module shares2mskstate
#
(
    parameter Nbits = 128,
    parameter d = 2
)
(
    input [d*Nbits-1:0] state_in,
    output [d*Nbits-1:0] state_out
);

genvar i,b;
generate
for(i=0;i<d;i=i+1) begin: sharing_ordering
    wire [Nbits-1:0] sharing = state_in[i*Nbits +: Nbits];
    
    for(b=0;b<Nbits;b=b+1) begin: bit_ordering
        // To be compliant with the gadgets: cst_mask uses the fist mask as MSB
        assign state_out[b*d+d-i-1] = sharing[b];
    end
end
endgenerate

endmodule
