/*
    This module implements the management of
    a flag signal
*/
module flag_core
(
    input clk,
    input rst,
    input syn_unset,
    input syn_set,
    output flag
);

wire en_update;
wire next_flag;

assign en_update = syn_unset | syn_set;
assign next_flag = syn_set & (~(syn_unset));

dff #(.SIZE(1),.ASYN(0))  
flag_reg(
    .clk(clk),
    .rst(rst),
    .d(next_flag),
    .en(en_update),
    .q(flag)
);


endmodule
