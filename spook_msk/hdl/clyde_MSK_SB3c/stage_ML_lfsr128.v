/*
    This module implement one stage of the 128-bits LFSR.
*/
module stage_ML_lfsr128
(
    input [127:0] in,
    output [127:0] out
);

wire feedback = ~(in[127] ^ in[125] ^ in[100] ^ in[98]);
assign out = {in[0 +: 127],feedback};

endmodule
