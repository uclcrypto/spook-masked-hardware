/*
   32-bits LFSR stage.
   Used to generate the constant values.
*/
module upd_lfsr
#
(
    parameter poly = 32'hc5
)
(
    input [31:0] lfsr_in,
    output [31:0] lfsr_out
);

wire [31:0] b_out_ext = lfsr_in[31] ? 32'hffffffff : 32'h0;
assign lfsr_out = (lfsr_in << 1) ^ (b_out_ext & poly);

endmodule
