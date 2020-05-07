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
    Change the data representation.
    Considering the input bundle as 
        bundle_in = [ b3[127:96] | b2[95:64] | b1[63:32] | b0[31:0] ]

    The column with index i ( in [0,31]) is
        c_i = [ b3[i] | b2[i] | b1[i] | b0[i] ]

    The output is
        cols = [ c_31 | c_30 | ... | c_1 | c_0 ]
*/
module bundle2cols
#
(
    // Number of masking shares
    parameter d = 1, 
    // Number of state bits
    parameter Nbits = 128 
)
(
    input [Nbits*d-1:0] bundle_in,
    output [Nbits*d-1:0] cols
);


genvar i,j;
generate
for(i=0;i<(Nbits/4);i=i+1) begin: cols_division
    for(j=0;j<d;j=j+1) begin: shared_col_generation
        wire [3:0] col;
        assign col[0] = bundle_in[4*j+i];
        assign col[1] = bundle_in[4*j+i+(Nbits/4)];
        assign col[2] = bundle_in[4*j+i+(Nbits/4)*2];
        assign col[3] = bundle_in[4*j+i+(Nbits/4)*3];
        assign cols[(i+1)*4*d-1+4*j:i*4*d+4*j] = col;
    end
end
endgenerate

endmodule
