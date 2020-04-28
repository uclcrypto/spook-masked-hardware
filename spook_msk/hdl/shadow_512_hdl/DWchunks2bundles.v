/*
    Change the shadow state representation.
    Used to process the Round B of Shadow
    Direct inverse of the module 'bundles2DWchunks'
*/
module DWchunks2bundles
(
    input [511:0] DWchunks,
    output [511:0] bundles
);

genvar r, b;
generate
for(r=0;r<4;r=r+1) begin:row
    for(b=0;b<4;b=b+1) begin: bundle
        assign bundles[128*b+32*r +: 32] = DWchunks[(4*r+b)*32 +: 32];
    end
end
endgenerate


endmodule
