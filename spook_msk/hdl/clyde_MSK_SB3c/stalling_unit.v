/*
    This module is used to stall the Clyde logic during the 
    randomness generation. 
*/
module stalling_unit
#(
    parameter RND_RATE_DIVIDER = 2
)
(
    input clk,
    input pre_syn_rst,
    input pre_enable_glob,
    input pre_need_rnd1,
    input pre_need_rnd2,
    input rnd_valid_next_enable1,
    input rnd_valid_next_enable2,
    input core_in_process,
    input pre_data_in_valid,
    output pre_enable_core,
    output pre_enable_run_prng1,
    output pre_enable_run_prng2,
    output ready_start_run,
    output data_in_valid
);

// enabling register for the stalling registers // 
reg enable_stalling_reg;
always@(posedge clk)
    enable_stalling_reg <= pre_enable_glob | pre_syn_rst;

reg syn_rst;
always@(posedge clk)
    syn_rst <= pre_syn_rst;

// The core is ready to start a new run
assign ready_start_run = ~core_in_process;
// A new run starts
wire start_run_acknowledgement = ready_start_run & pre_data_in_valid;

wire start_run_acknowledged;
dff #(.SIZE(1),.ASYN(0))
prev_start_acknoledged_reg(
    .clk(clk),
    .rst(syn_rst),
    .d(start_run_acknowledgement),
    .en(enable_stalling_reg),
    .q(start_run_acknowledged)
);

/////// Status of randomness 1 ///////
// Stalling register prng1 //
wire next_stall_from_prng1;
wire stall_from_prng1;
dff #(.SIZE(1),.ASYN(0))
stall_reg1(
    .clk(clk),
    .rst(syn_rst),
    .d(next_stall_from_prng1),
    .en(enable_stalling_reg),
    .q(stall_from_prng1)
);

// Stalling register prng2 //
wire next_stall_from_prng2;
wire stall_from_prng2;
dff #(.SIZE(1),.ASYN(0))
stall_reg2(
    .clk(clk),
    .rst(syn_rst),
    .d(next_stall_from_prng2),
    .en(enable_stalling_reg),
    .q(stall_from_prng2)
);

wire init_pre_need_rnd = pre_need_rnd1 & start_run_acknowledged;
wire init_stall_req = init_pre_need_rnd & ~rnd_valid_next_enable1;

wire in_proc_pre_need_rnd1 = core_in_process & (pre_need_rnd1 | stall_from_prng1);
wire in_proc_stall_req1 = in_proc_pre_need_rnd1 & ~rnd_valid_next_enable1;

wire in_proc_pre_need_rnd2 = core_in_process & (pre_need_rnd2 | stall_from_prng2);
wire in_proc_stall_req2 = in_proc_pre_need_rnd2 & ~rnd_valid_next_enable2;

assign next_stall_from_prng1 = init_stall_req | in_proc_stall_req1;
assign next_stall_from_prng2 = in_proc_stall_req2;

// The pre enable signal of the PRNG
assign pre_enable_run_prng1 = init_pre_need_rnd | in_proc_pre_need_rnd1;
assign pre_enable_run_prng2 = in_proc_pre_need_rnd2;

// Core enable and glob ready signals ///
wire init_mask_pre_enable_core = start_run_acknowledgement | (start_run_acknowledged & ~init_stall_req);
wire in_proc_mask_pre_en_prng1 = (rnd_valid_next_enable1 | ~(pre_need_rnd1 | stall_from_prng1));
wire in_proc_mask_pre_en_prng2 = (rnd_valid_next_enable2 | ~(pre_need_rnd2 | stall_from_prng2));
wire in_proc_mask_pre_enable_core = core_in_process & in_proc_mask_pre_en_prng1 & in_proc_mask_pre_en_prng2;

wire mask_pre_enable_core = init_mask_pre_enable_core | in_proc_mask_pre_enable_core;
assign pre_enable_core = pre_enable_glob & mask_pre_enable_core;  

assign data_in_valid = start_run_acknowledged;


endmodule
