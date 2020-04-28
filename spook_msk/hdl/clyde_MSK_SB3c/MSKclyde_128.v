/*
    Top module for the Clyde primitive. 
*/
module MSKclyde_128
#
(
    parameter d=2,
    parameter Ns = 6,
    parameter PDSBOX = 2,
    parameter PDLBOX = 1,
    parameter Nbits=128,
    parameter RND_RATE_DIVIDER = 1,
    parameter SIZE_FEED = 32,
    parameter ALLOW_SPEED_ARCH=0
)
(
    clk,
    pre_syn_rst,
    inverse,
    data_in,
    pre_data_in_valid,
    sharing_key,
    tweak,
    data_out,
    pre_data_out_valid,
    pre_enable,
    // PRNG ports //
    feed1,
    feed_data,
    feed2,
    ready_start_run
);


`include "spook_sbox_rnd.inc"

/////// Generation parameters ////////////
// Actual SB divider - how many chuncks to serially process.
localparam SB_DIVIDER = 2**PDSBOX;
// Actual LB divider - how many chuncks to serially process.
localparam LB_DIVIDER = 2**PDLBOX;
// Size of each randomness bus (in bits)
localparam SIZE_SB_RND = (spook_sbox_rnd*32/SB_DIVIDER)/2;
// Size of a sharing (in bits)
localparam SIZE_SHARING = d*Nbits;

input clk;
input pre_syn_rst;
input inverse;
input [Nbits-1:0] data_in;
input pre_data_in_valid;
input [SIZE_SHARING-1:0] sharing_key;
input [Nbits-1:0] tweak;
output [Nbits-1:0] data_out;
output pre_data_out_valid;
input pre_enable;
input feed1;
input [SIZE_FEED-1:0] feed_data;
input feed2;
output ready_start_run;

// PRNG rnd1 SB //
wire pre_enable_run_prng1;
wire rnd_valid_next_enable1;
wire [SIZE_SB_RND-1:0] rnd1;

prng_unit #(.SIZE_RND(SIZE_SB_RND),.SIZE_GEN(SIZE_SB_RND/RND_RATE_DIVIDER),.SIZE_FEED(SIZE_FEED))
prng1(
    .clk(clk),
    .pre_rst(pre_syn_rst),
    .pre_enable_run(pre_enable_run_prng1),
    .feed(feed1),
    .feed_data(feed_data),
    .rnd_valid_next_enable(rnd_valid_next_enable1),
    .rnd_out(rnd1)
);

// PRNG rnd2 SB //
wire pre_enable_run_prng2;
wire rnd_valid_next_enable2;
wire [SIZE_SB_RND-1:0] rnd2;

prng_unit #(.SIZE_RND(SIZE_SB_RND),.SIZE_GEN(SIZE_SB_RND/RND_RATE_DIVIDER),.SIZE_FEED(SIZE_FEED))
prng2(
    .clk(clk),
    .pre_rst(pre_syn_rst),
    .pre_enable_run(pre_enable_run_prng2),
    .feed(feed2),
    .feed_data(feed_data),
    .rnd_valid_next_enable(rnd_valid_next_enable2),
    .rnd_out(rnd2)
);

// Clyde core //
wire [SIZE_SHARING-1:0] sharing_data_out;
wire pre_enable_core;
wire pre_need_rnd1;
wire pre_need_rnd2;
wire in_process_status;
wire dut_data_in_valid;

MSKclyde_128_1R #(
    .d(d),
    .Ns(Ns),
    .PDSBOX(PDSBOX),
    .PDLBOX(PDLBOX),
    .Nbits(Nbits),
    .ALLOW_SPEED_ARCH(ALLOW_SPEED_ARCH)
)
clyde_core(
    .clk(clk),
    .pre_syn_rst(pre_syn_rst),
    .inverse(inverse),
    .data_in_valid(dut_data_in_valid),
    .data_in(data_in),
    .sharing_key(sharing_key),
    .tweak(tweak),
    .sharing_data_out(sharing_data_out),
    .pre_sharing_data_out_valid(pre_data_out_valid),
    .pre_enable(pre_enable_core),
    .rnd1_SB(rnd1),
    .rnd2_SB(rnd2),
    .pre_need_rnd1_SB(pre_need_rnd1),
    .pre_need_rnd2_SB(pre_need_rnd2),
    .in_process_status(in_process_status)
);

/////// Stalling mechanism ////////
stalling_unit #(.RND_RATE_DIVIDER(RND_RATE_DIVIDER))
stall_mec(
    .clk(clk),
    .pre_syn_rst(pre_syn_rst),
    .pre_enable_glob(pre_enable),
    .pre_need_rnd1(pre_need_rnd1),
    .pre_need_rnd2(pre_need_rnd2),
    .rnd_valid_next_enable1(rnd_valid_next_enable1),
    .rnd_valid_next_enable2(rnd_valid_next_enable2),
    .core_in_process(in_process_status),
    .pre_data_in_valid(pre_data_in_valid),
    .pre_enable_core(pre_enable_core),
    .pre_enable_run_prng1(pre_enable_run_prng1),
    .pre_enable_run_prng2(pre_enable_run_prng2),
    .ready_start_run(ready_start_run),
    .data_in_valid(dut_data_in_valid)
);

// Recombination mecanism //
genvar i;
generate
for(i=0;i<Nbits;i=i+1) begin: rec_bit_out
    assign data_out[i] = ^(sharing_data_out[d*i +: d]);    
end
endgenerate

endmodule
