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
    This module performs the Round B (reduced) of the Shadow primitive.
    More specifically, the following operation are performed:
        -Dbox layer 
        -32-bits constant addition 
*/
module DW_unit
#
(
    // Nbits - State bundle bits: amount of bits per bundle
    parameter Nbits = 128, 
    // BAmount - Bundle amount: amount of bundle in the state
    parameter BAmount = 4,
    // SERIALISATION
    parameter DIVIDER = 4
)
(
    in_bundles_state,
    W32,
    out_bundles_state
);

// Ports generation params //
// Amount of bits in the full state
localparam SNbits = Nbits*BAmount;

// IOs ports //
input [SNbits-1:0] in_bundles_state;
input [31:0] W32;
output [SNbits-1:0] out_bundles_state;

// state as DW chunks //
wire [SNbits-1:0] state_DWchunks;
bundles2DWchunks
b2DWin(
    .bundles(in_bundles_state),
    .DWchunks(state_DWchunks)
);

// Actual chunks processed //
localparam chunkAm = 4/DIVIDER;
wire [Nbits*chunkAm-1:0] pDWchunks = state_DWchunks[0 +: Nbits*chunkAm];

// Dbox layer //
wire [Nbits*chunkAm-1:0] pDWchunks_post_DBOX;
genvar c;
generate
    for(c=0;c<chunkAm;c=c+1) begin: db_mls
        dbox_mls 
        dbchunk(
            .lfsr(W32[c*32 +: 32]),
            .x0(pDWchunks[Nbits*c+0 +: 32]),
            .x1(pDWchunks[Nbits*c+32 +: 32]),
            .x2(pDWchunks[Nbits*c+64 +: 32]),
            .x3(pDWchunks[Nbits*c+96 +: 32]),
            .y0(pDWchunks_post_DBOX[Nbits*c+0 +: 32]),
            .y1(pDWchunks_post_DBOX[Nbits*c+32 +: 32]),
            .y2(pDWchunks_post_DBOX[Nbits*c+64 +: 32]),
            .y3(pDWchunks_post_DBOX[Nbits*c+96 +: 32])
        );
    end
endgenerate

// Recombine all the chunks //
wire [SNbits-1:0] rec_DWchunks;
generate 
if(DIVIDER==1) begin
    assign rec_DWchunks = pDWchunks_post_DBOX;
end else begin
    assign rec_DWchunks = {pDWchunks_post_DBOX,state_DWchunks[SNbits-1:Nbits*chunkAm]};
end
endgenerate

// Retransform as bundles
DWchunks2bundles
DW2bout(
    .DWchunks(rec_DWchunks),
    .bundles(out_bundles_state)
);

endmodule
