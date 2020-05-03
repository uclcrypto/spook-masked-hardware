/*
    This module implement the 128-bits LFSR used to generate 
    the randomness.
*/
module prng_unit
#
(
    parameter SIZE_RND = 128,
    parameter SIZE_GEN = 1,
    parameter SIZE_FEED = 32 
)
(
    input pre_enable_run,
    input lock_feed,
    input pre_rst,
    input clk,
    input feed,
    // Practically fed at t1 if pre_feed is set at t0
    input [SIZE_FEED-1:0] feed_data,
    // The rnd is valid 1 cycle the next time the core is enabled.
    output rnd_valid_next_enable,
    output pre_rnd_valid_next_enable,
    output [SIZE_RND-1:0] rnd_out
);

// Global enable signal //
reg glob_enable;
always@(posedge clk)
    glob_enable <= pre_rst | feed | (~lock_feed & pre_enable_run);

// Feeding flag //
reg ctrl_feed;
always@(posedge clk)
    ctrl_feed <= feed | lock_feed;

reg [SIZE_FEED-1:0] feed_data_barrier;
always@(posedge clk)
    feed_data_barrier <= feed_data;

reg rst;
always@(posedge clk)
    rst = pre_rst;

// DATAPATH /////////////////////////////
// LFSR state ///////////////////////////
wire [127:0] lfsr_state;
wire [127:0] next_lfsr_state;
dff #(.SIZE(128),.ASYN(0))
reg_lfsr_state(
    .clk(clk),
    .rst(1'b0),
    .d(next_lfsr_state),
    .en(glob_enable),
    .q(lfsr_state)
);

// Updating lfsr state logic ////////////
wire [SIZE_GEN-1:0] Q;
genvar i;
generate
for(i=0;i<SIZE_GEN;i=i+1) begin: lfsr_stage
    wire [127:0] in_logic, out_logic;
    assign Q[i] = out_logic[0];

    stage_ML_lfsr128 lfsr_logic_core(
        .in(in_logic),
        .out(out_logic)
    );

    if(i==0) begin
        assign in_logic = lfsr_state;
    end else begin
        assign in_logic = lfsr_stage[i-1].out_logic;
    end

end
endgenerate

wire [127:0] updated_lfsr_state = lfsr_stage[SIZE_GEN-1].out_logic;

generate
if(SIZE_FEED == 128) begin
    assign next_lfsr_state = ctrl_feed ? feed_data_barrier : updated_lfsr_state;
end else begin
    assign next_lfsr_state = ctrl_feed ? {feed_data_barrier, lfsr_state[SIZE_FEED +: 128-SIZE_FEED]} : updated_lfsr_state;
end
endgenerate

// Randomness handling
localparam RND_LAT = SIZE_RND / SIZE_GEN;
parameter CNT_SIZE = $clog2(RND_LAT) + 1;

// Buffer reg (used to avoid glitches)
(* KEEP = "TRUE", S = "TRUE", DONT_TOUCH = "TRUE" *)
wire [SIZE_RND-1:0] next_rnd_buffer;
dff #(.SIZE(SIZE_RND),.ASYN(0))
rnd_buffer_reg(
    .clk(clk),
    .rst(1'b0),
    .d(next_rnd_buffer),
    .en(glob_enable),
    .q(rnd_out)
);

generate
if(RND_LAT == 1) begin
    // rnd_validity
    wire rnd_validity;
    wire next_rnd_validity = glob_enable & ~lock_feed;
    wire rst_rnd_validity = feed | lock_feed;
    dff #(.SIZE(1),.ASYN(0))
    dff_rnd_valid(
        .clk(clk),
        .rst(rst_rnd_validity),
        .d(next_rnd_validity),
        .en(glob_enable),
        .q(rnd_validity)
    );

    assign rnd_valid_next_enable = rnd_validity;
    assign pre_rnd_valid_next_enable = next_rnd_validity | rnd_validity;

    assign next_rnd_buffer = Q;

    

end else begin

    // Todo add pre_rnd_valid_next_enable.

    // Randomness generated in multiple cycles
    wire rst_rnd_cnt;
    wire init_generation_done;
    wire pre_pre_buffer_full;
    wire pre_buffer_full;
    wire buffer_full;

    wire [CNT_SIZE-1:0] rnd_cnt;
    wire [CNT_SIZE-1:0] next_rnd_cnt = rnd_cnt + 1'b1;

    if(RND_LAT==2) begin
        assign pre_pre_buffer_full = init_generation_done ? rst_rnd_cnt : (rnd_cnt == 0);
    end else begin
        assign pre_pre_buffer_full = (init_generation_done ? (rnd_cnt == RND_LAT-3) : (rnd_cnt == RND_LAT-2)) & ~rst_rnd_cnt;
    end

    assign pre_buffer_full = (init_generation_done ? (rnd_cnt == RND_LAT-2) : (rnd_cnt == RND_LAT-1)) & ~rst_rnd_cnt;
    assign buffer_full = init_generation_done ? (rnd_cnt == (RND_LAT-1)) : (rnd_cnt == RND_LAT);
    assign rst_rnd_cnt =  (buffer_full & glob_enable) | rst | ctrl_feed;

    dff #(.SIZE(CNT_SIZE),.ASYN(0))   
    rnd_cnt_reg(
        .clk(clk),
        .rst(rst_rnd_cnt),
        .d(next_rnd_cnt),
        .en(glob_enable & ~buffer_full),
        .q(rnd_cnt)
    );
 
    wire rst_init_flag = rst | ctrl_feed;
    dff #(.SIZE(1),.ASYN(0))
    dff_init_gen(
        .clk(clk),
        .rst(rst_init_flag),
        .d(buffer_full | init_generation_done),
        .en(glob_enable),
        .q(init_generation_done)
    );

    assign rnd_valid_next_enable = (( pre_buffer_full & glob_enable & ~ctrl_feed & ~rst_rnd_cnt) | (buffer_full & ~glob_enable)) & ~rst;
    
    if(RND_LAT==2) begin
        assign pre_rnd_valid_next_enable = ((pre_pre_buffer_full & glob_enable & ~ctrl_feed) | (pre_buffer_full & ~glob_enable)) & ~rst;
    end else begin
        assign pre_rnd_valid_next_enable = ((pre_pre_buffer_full & glob_enable & ~ctrl_feed & ~rst_rnd_cnt) | (pre_buffer_full & ~glob_enable)) & ~rst;
    end

    assign next_rnd_buffer = {Q,rnd_out[SIZE_GEN +: SIZE_RND-SIZE_GEN]};

end
endgenerate


endmodule
