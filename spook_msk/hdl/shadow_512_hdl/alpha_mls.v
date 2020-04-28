module alpha_mls
(
    input [31:0] x_in,
    output [31:0] x_out
);

wire [31:0] b = (x_in >> 31);
assign x_out = (x_in << 1) ^ b ^(b << 8);

endmodule
