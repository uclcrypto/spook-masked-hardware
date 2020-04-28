/* 
    This module implements the LFSR used to
    generate the 32-bits constant for the Shadow primitive
*/
module lfsr_32
#(
    parameter poly = 32'hc5,
    parameter state_init = 32'hf8737400
)
(
    input clk,
    input n_syn_rst,
    input enable,
    output [31:0] lfsr_state
);

reg [31:0] state;
wire [31:0] nextstate;

upd_lfsr #(.poly(poly))
xt_lfsr(
    .lfsr_in(state),
    .lfsr_out(nextstate)
);

always@(posedge clk)
if(~n_syn_rst)
    state <= state_init;
else if(enable)
    state <= nextstate; 

assign lfsr_state = state;

endmodule
