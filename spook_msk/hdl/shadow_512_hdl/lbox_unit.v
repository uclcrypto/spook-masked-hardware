/*
    This module performs the Lbox layer.
    This layer can be serialized using the 
    PDLBOX parameter (power of two lbox divider).
    More specifically:
        PDLBOX= 
        0: 2 Lboxes (128-bits processed in parallel)
        1: 1 Lbox (64-bits processed in parallel) 
*/
module lbox_unit
#
(
    parameter PDLBOX = 0,
    // Number of state bits.
    parameter Nbits = 128
)
(
    bundle_in,
    bundle_out
);

// Generation params ////////////////
// Amount of LB bundles
localparam AM_COLS_bund = 2**PDLBOX; 
// Size of LB bundles
localparam SIZE_LBOX_bund = Nbits/AM_COLS_bund; 
// Amount of LB
localparam AM_LB = 2/AM_COLS_bund;

// Ios ports 
input [SIZE_LBOX_bund-1:0] bundle_in;
output [SIZE_LBOX_bund-1:0] bundle_out;


localparam Nbdiv2 = Nbits/2;
localparam Nbdiv4 = Nbits/4;

genvar i;
generate
for(i=0;i<AM_LB;i=i+1) begin: lb
    lbox lbi(
        //.x(bundle_in[31+64*i:64*i]),
        .x(bundle_in[i*Nbdiv2 +: Nbdiv4]),
        .y(bundle_in[i*Nbdiv2 + Nbdiv4 +: Nbdiv4]),
        .a(bundle_out[i*Nbdiv2 +: Nbdiv4]),
        .b(bundle_out[i*Nbdiv2 + Nbdiv4 +: Nbdiv4])
    );
end
endgenerate


endmodule
