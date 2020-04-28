/*
    This module implements the logic to 
    compute the value of the 4-bits constant 
    during the a decryption computation.
*/
module Winv(
    input [3:0] W,
    output [3:0] prevW
);

wire pad_with_1 = W[0];
wire [3:0] term0 = pad_with_1 ? 4'b1000 : 4'b0000;
wire [3:0] term1 = pad_with_1 ? 4'b0011 : 4'b0000;
wire [3:0] shifted_r_W = (W ^ term1) >> 1;

assign prevW = shifted_r_W ^ term0;


endmodule
