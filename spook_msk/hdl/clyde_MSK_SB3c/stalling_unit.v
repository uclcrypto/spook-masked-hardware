/*
    This module is used to stall the Clyde logic during the 
    randomness generation. 
*/
module stalling_unit
#
(
    parameter RND_RATE_DIVIDER = 1 
)
(
    input clk,
    input pre_syn_rst,
    input pre_enable_glob,
    input pre_pre_need_rnd1,
    input pre_need_rnd1,
    input pre_pre_need_rnd2,
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

// prng ready to start
wire init_config = ~core_in_process;
wire prng1_rdy = rnd_valid_next_enable1;
wire prng2_rdy = rnd_valid_next_enable2;
wire prngs_rdy = prng1_rdy & prng2_rdy;

// The core is ready to start a new run
wire valid_start_run;
assign ready_start_run = prngs_rdy & init_config & ~valid_start_run;

// Valid start run 
wire valid_pre_start_run = pre_data_in_valid & ready_start_run;
dff #(.SIZE(1),.ASYN(0))
dff_started(
    .clk(clk),
    .rst(syn_rst),
    .d(valid_pre_start_run),
    .en(enable_stalling_reg),
    .q(valid_start_run)
);


// Stall registers
wire stall_from_prng1, stall_from_prng2;
wire next_flag_stall1, next_flag_stall2;
wire flag_stall1, flag_stall2;
wire rst_f1, rst_f2;

dff #(.SIZE(1),.ASYN(0))
dff_stall1(
    .clk(clk),
    .rst(rst_f1),
    .d(next_flag_stall1),
    .en(enable_stalling_reg),
    .q(flag_stall1)
);

dff #(.SIZE(1),.ASYN(0))
dff_stall2(
    .clk(clk),
    .rst(rst_f2),
    .d(next_flag_stall2),
    .en(enable_stalling_reg),
    .q(flag_stall2)
);

assign stall_from_prng1 = pre_need_rnd1 & ~rnd_valid_next_enable1;
assign stall_from_prng2 = pre_need_rnd2 & ~rnd_valid_next_enable2;

assign next_flag_stall1 = stall_from_prng1 | flag_stall1;
assign next_flag_stall2 = stall_from_prng2 | flag_stall2;

assign rst_f1 = syn_rst | flag_stall1 & rnd_valid_next_enable1;
assign rst_f2 = syn_rst | flag_stall2 & rnd_valid_next_enable2;

// Core enable and glob ready signals //
wire stalled_core = flag_stall1 | flag_stall2;

wire stall_req = stall_from_prng1 | stall_from_prng2;
wire pre_need_rnd = pre_need_rnd1 | pre_need_rnd2;
wire pre_pre_need_rnd = pre_pre_need_rnd1 | pre_pre_need_rnd2;

// The pre enable signal of the PRNG
generate
if (RND_RATE_DIVIDER==1) begin
    assign pre_enable_run_prng1 = init_config ? (prng1_rdy ? valid_pre_start_run | (valid_start_run & rnd_valid_next_enable1) : (valid_start_run ? pre_pre_need_rnd1 : 1'b1)) : (stall_from_prng1 | flag_stall1) & ~rnd_valid_next_enable1 | pre_pre_need_rnd1;

    assign pre_enable_run_prng2 = init_config ? (prng2_rdy ? valid_pre_start_run | (valid_start_run & rnd_valid_next_enable2) : (valid_start_run ? pre_pre_need_rnd2 : 1'b1)) : (stall_from_prng2 | flag_stall2) & ~rnd_valid_next_enable2 | pre_pre_need_rnd2;
end else begin
    assign pre_enable_run_prng1 = init_config ? (prng1_rdy ? valid_pre_start_run | (valid_start_run & rnd_valid_next_enable1) : (valid_start_run ? pre_pre_need_rnd1 : 1'b1)) : (stall_from_prng1 | flag_stall1) & ~rnd_valid_next_enable1 | pre_pre_need_rnd1 | pre_need_rnd1;

    assign pre_enable_run_prng2 = init_config ? (prng2_rdy ? valid_pre_start_run | (valid_start_run & rnd_valid_next_enable2) : (valid_start_run ? pre_pre_need_rnd2 : 1'b1)) : (stall_from_prng2 | flag_stall2) & ~rnd_valid_next_enable2 | pre_pre_need_rnd1 | pre_pre_need_rnd2 | pre_need_rnd2;
end
endgenerate

assign pre_enable_core = pre_enable_glob & (init_config ? (valid_pre_start_run) | (valid_start_run & (pre_need_rnd ? ~stall_req : 1'b1)) : (stalled_core ? (flag_stall1 & rst_f1) | (flag_stall2 & rst_f2)  : ((pre_pre_need_rnd | pre_need_rnd) ? ~stall_req : 1'b1))); 
assign data_in_valid = valid_start_run;


endmodule
