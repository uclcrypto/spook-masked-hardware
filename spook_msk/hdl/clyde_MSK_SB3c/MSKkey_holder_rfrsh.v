/*
    Top module of the key holder/refresher. 
*/
module MSKkey_holder_rfrsh
#
(
    parameter d=2,
    parameter Nbits=128,
    parameter SIZE_FEED=32,
    parameter SIZE_RND_GEN=1
)
(
    clk,
    pre_rst,
    // BUS IN
    data_in,
    data_in_valid,
    // OUT
    sharing_key_out,
    // Global control
    n_lock_for_seed,
    feed_prng_seed,
    rnd_ready,
    pre_pre_refresh
);

localparam SIZE_SHARING = d*Nbits;
localparam SIZE_RND_RFSH = (d-1)*Nbits;

input clk;
input pre_rst;
input [SIZE_FEED-1:0] data_in;
input data_in_valid;
output [SIZE_SHARING-1:0] sharing_key_out;
input n_lock_for_seed;
input feed_prng_seed;
output rnd_ready;
input pre_pre_refresh;


// PRNG unit
wire pre_enable_run_prng;
wire [SIZE_RND_RFSH-1:0] rnd;
prng_unit #(.SIZE_RND(SIZE_RND_RFSH),.SIZE_GEN(SIZE_RND_GEN),.SIZE_FEED(SIZE_FEED))
prng_core(
    .pre_enable_run(pre_enable_run_prng),
    .pre_rst(pre_rst),
    .clk(clk),
    .feed(feed_prng_seed & data_in_valid),
    .feed_data(data_in),
    .rnd_valid_next_enable(rnd_ready),
    .rnd_out(rnd)
);

assign pre_enable_run_prng = (~rnd_ready & n_lock_for_seed) | pre_pre_refresh | pre_rst;

// Key holder unit
MSKkey_holder #(.d(d),.Nbits(Nbits),.FEED_SIZE(SIZE_FEED))
key_holder(
    .clk(clk),
    .rnd(rnd),
    .data_in(data_in),
    .data_in_valid(~feed_prng_seed & data_in_valid),
    .sharing_key(sharing_key_out),
    .pre_pre_refresh(pre_pre_refresh)
);


endmodule 
