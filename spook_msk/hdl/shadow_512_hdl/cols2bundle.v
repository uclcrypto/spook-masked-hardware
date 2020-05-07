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
    Change the data representation
    Inverse of the module bundle2cols
*/
module cols2bundle
#
(
    // Number of masking shares
    parameter d = 1, 
    // Number of state bits
    parameter Nbits = 128 
)
(
    input [Nbits*d-1:0] cols,
    output [Nbits*d-1:0] bundle_out
);

genvar i,j;
generate
for(i=0;i<(Nbits/4);i=i+1) begin: cols_division
    for(j=0;j<d;j=j+1) begin: shared_bundle_generation
        wire [3:0] col;
        assign col = cols[(i+1)*4*d-1+4*j:i*4*d+4*j];
        assign bundle_out[4*j+i] = col[0];
        assign bundle_out[4*j+i+(Nbits/4)] = col[1];
        assign bundle_out[4*j+i+(Nbits/4)*2] = col[2];
        assign bundle_out[4*j+i+(Nbits/4)*3] = col[3];
    end
end
endgenerate

endmodule
