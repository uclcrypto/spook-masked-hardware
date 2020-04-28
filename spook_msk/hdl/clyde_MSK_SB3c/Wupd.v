/*
    This module implements the logic to 
    compute the value of the 4-bits constant 
    during the an encryption computation.
*/
module Wupd(
    input [3:0] W,
    output [3:0] nextW
);

wire [3:0] shifted_W = W << 1;
wire [3:0] term = W[3] ? 4'b11 : 4 'b0;

assign nextW = shifted_W ^ term;

endmodule
