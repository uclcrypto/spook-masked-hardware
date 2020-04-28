/*
    This module encodes a header to be sent
    in the communication protocole.
*/
module header_encoder
(
    input [3:0] dtype,
    input eot,
    input eoi,
    input last,
    input [15:0] length,
    // Encoded header
    output [31:0] header
);

assign header = {dtype,1'b0,eot,eoi,last,7'b0,1'b1,length};


endmodule
