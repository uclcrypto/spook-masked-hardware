/*
    This module implement the phi operation and its inverse. 
    This operation is used in the tweakeys values computations.
*/
module phi_dual(
    input [127:0] phi_in,
    input inverse,
    output [127:0] phi_out
);

// temporary node
wire [63:0] t0,t1, tX;

// Computation
assign t0 = phi_in[63:0];
assign t1 = phi_in[127:64];
assign tX = t0 ^ t1;

// phi computation
assign phi_out = inverse ? {tX,t1} : {t0,tX};

endmodule
