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
    Change the Shadow state representation.
    Used to process the Round B of Shadow.
    Considering the shadow state as 4 128-bits bundles:
        bundles = [ b3 | b2 | b1 | b0 ]

    Each bundle is considered as 4 32-bits rows:
        bi = [ ri_3 | ri_2 | ri_1 | ri_0 ]

    A DWchunk is a bundle composed of the rows with the same 
    indexes from each bundles in the state of Shadow:
        DWchunk_j = [ r3_j | r2_j | r1_j | r0_j ]

    The output is 
        DWchunks = [ DWchunk_3 | DWchunk_2 | DWchunk_1 | DWchunk_0 ]
*/
module bundles2DWchunks
(
    input [511:0] bundles,
    output [511:0] DWchunks
);

genvar r, b;
generate
for(r=0;r<4;r=r+1) begin:row
    for(b=0;b<4;b=b+1) begin: bundle
        assign DWchunks[(4*r+b)*32 +: 32] = bundles[128*b+32*r +: 32];
    end
end
endgenerate

endmodule
