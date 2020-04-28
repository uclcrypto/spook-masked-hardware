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
