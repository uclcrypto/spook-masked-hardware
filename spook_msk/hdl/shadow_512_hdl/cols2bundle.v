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
