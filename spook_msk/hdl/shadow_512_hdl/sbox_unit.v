/*
    This module performs the Sbox layer.
    This layer can be serialized using the
    PDSBOX parameter (power of two sbox divider).
    More specifically:
        PDSBOX=
        0: 32 Sboxes (128-bits processed in parallel)
        1: 16 Sboxes (64-bits processed in parallel)
        2: 8 Sboxes (32-bits processed in parallel)
        3: 4 Sboxes (16-bits processed in parallel)
        4: 2 Sboxes (8-bits processed in parallel)
        5: 1 Sbox (4-bits processed in parallel)
*/
module sbox_unit
#
(
    parameter PDSBOX = 0,
    // Number of state bits.
    parameter Nbits = 128 
)
(
    cols,
    cols_post_sb
);

// Generation params (DO NOT TOUCH) ///////////
// Amount of column bundles
localparam AM_BUND_cols = 2**PDSBOX; 
// Size of each column bundles
localparam SIZE_BUND_cols = Nbits/AM_BUND_cols; 
// Amount of column per column bundles
localparam AM_cols = 32/AM_BUND_cols; 

// IOs ports 
input [SIZE_BUND_cols-1:0] cols;
output [SIZE_BUND_cols-1:0] cols_post_sb;

genvar i;
generate
for(i=0;i<AM_cols;i=i+1) begin: sb
    sbox sbi(
        .in(cols[i*4 +: 4]),
        .out(cols_post_sb[i*4 +: 4])
    );
end
endgenerate


endmodule
