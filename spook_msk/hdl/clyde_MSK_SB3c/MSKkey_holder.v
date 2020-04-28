/*
    Key holder. This module holds the sharing of the key  
    and includes the logic used to refresh the sharing.
*/
module MSKkey_holder
#
(
    parameter d = 2,
    parameter Nbits = 128,
    parameter FEED_SIZE = 32
)
(
    clk,
    // Active low synchronous reset signal
    rnd,
    // Feeding data (a full key is provided by successive data chunks)
    data_in,
    data_in_valid,
    // Outputted share ok the key
    sharing_key,
    // Refresh (the randomness is loaded at t+1, the key shares refreshed at t+2 and the key valid at t+3)
    pre_pre_refresh
);

input clk;
input [(d-1)*Nbits-1:0] rnd;
input [FEED_SIZE-1:0] data_in;
input data_in_valid;
output [d*Nbits-1:0] sharing_key;
input pre_pre_refresh;

// Shares of 0 based on the randomness //
wire [d*Nbits-1:0] sharing_zero;
MSKzeros_sharing #(.d(d),.Nbits(Nbits))
sh_zeros(
    .rnd(rnd),
    .zeros(sharing_zero)
);

// 0 sharing register
wire [d*Nbits-1:0] sharing_rfrsh;
wire en_rfrsh_reg;
MSKregEn_par #(.d(d),.count(Nbits))
rfrsh_reg(
    .clk(clk),
    .rst(1'b0),
    .en(en_rfrsh_reg),
    .in(sharing_zero),
    .out(sharing_rfrsh)
);

// Key register // 
wire [d*Nbits-1:0] next_sharing_key;
wire [d*Nbits-1:0] shares_key_tmp;
wire en_key_reg;
MSKregEn_par #(.d(d),.count(Nbits))
key_reg(
    .clk(clk),
    .rst(1'b0),
    .en(en_key_reg),
    .in(next_sharing_key),
    .out(shares_key_tmp)
);

shares2mskstate #(.d(d),.Nbits(Nbits))
TR_msk2st(
    .state_in(shares_key_tmp),
    .state_out(sharing_key)
);

// Refresh xor //
wire [d*Nbits-1:0] rfrsh_sharing_key;
MSKxor_par #(.d(d),.count(Nbits))
xor_rfrsh(
    .ina(shares_key_tmp),
    .inb(sharing_rfrsh),
    .out(rfrsh_sharing_key)
);

// Input delay register //
wire [FEED_SIZE-1:0] delayed_data_in;
dff #(.SIZE(FEED_SIZE),.ASYN(0))
delay_reg(
    .clk(clk),
    .rst(1'b0),
    .d(data_in),
    .en(1'b1),
    .q(delayed_data_in)
);

// Shifted key reg value //
wire [d*Nbits-1:0] shifted_sharing_key = {delayed_data_in,shares_key_tmp[FEED_SIZE +: d*Nbits-FEED_SIZE]};

// Feeding mux //
wire ctrl_mux_feed;
MSKmux_par #(.d(d),.count(Nbits))
mux_next_key(
    .sel(ctrl_mux_feed),
    .in_true(shifted_sharing_key),
    .in_false(rfrsh_sharing_key),
    .out(next_sharing_key)
);

// Control logic //
// stable en_rfrsh_reg signal
dff #(.SIZE(1),.ASYN(0))
stable_en_rfrsh_reg(
    .clk(clk),
    .rst(1'b0),
    .d(pre_pre_refresh),
    .en(1'b1),
    .q(en_rfrsh_reg)
);

// stable en_key_reg signal
wire pre_en_key_reg = data_in_valid | en_rfrsh_reg;
dff #(.SIZE(1),.ASYN(0))
stable_en_key_reg(
    .clk(clk),
    .rst(1'b0),
    .d(pre_en_key_reg),
    .en(1'b1),
    .q(en_key_reg)
);

// delayed data validity to cntrl mux
dff #(.SIZE(1),.ASYN(0))
reg_ctrl_mux_feed(
    .clk(clk),
    .rst(1'b0),
    .d(data_in_valid),
    .en(1'b1),
    .q(ctrl_mux_feed)
);


endmodule



