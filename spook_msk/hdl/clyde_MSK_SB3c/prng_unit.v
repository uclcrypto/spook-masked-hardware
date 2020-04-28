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
    input pre_rst,
    input clk,
    input feed,
    // Practically fed at t1 if pre_feed is set at t0
    input [SIZE_FEED-1:0] feed_data,
    // The rnd is valid 1 cycle the next time the core is enabled.
    output rnd_valid_next_enable,
    output [SIZE_RND-1:0] rnd_out
);

// Global enable signal //
reg glob_enable;
always@(posedge clk)
    glob_enable <= pre_rst | feed | pre_enable_run;

// Feeding flag //
reg ctrl_feed;
always@(posedge clk)
    ctrl_feed <= feed;

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
parameter CNT_SIZE = ((RND_LAT % 2) == 0) ? $clog2(RND_LAT) : $clog2(RND_LAT) + 1;
localparam BUF_SIZE = SIZE_RND-SIZE_GEN;

generate
if(RND_LAT == 1) begin
    assign rnd_valid_next_enable = ~rst;
    assign rnd_out = Q;

end else begin
    // Randomness generated in multiple cycles
    wire [BUF_SIZE-1:0] rnd_buffer;
    wire [BUF_SIZE-1:0] next_rnd_buffer;
    wire rst_rnd_cnt;
    dff #(.SIZE(BUF_SIZE),.ASYN(0))
    rnd_buffer_reg(
        .clk(clk),
        .rst(1'b0),
        .d(next_rnd_buffer),
        .en(glob_enable),
        .q(rnd_buffer)
    );

    if(BUF_SIZE==SIZE_GEN) begin
        assign next_rnd_buffer = Q;
    end else begin
        assign next_rnd_buffer = {Q,rnd_buffer[SIZE_GEN +: BUF_SIZE-SIZE_GEN]};
    end

    wire [CNT_SIZE-1:0] rnd_cnt;
    wire [CNT_SIZE-1:0] next_rnd_cnt = rnd_cnt + 1'b1;

    wire pre_process_rnd = rnd_valid_next_enable & pre_enable_run;
    wire buffer_full = rnd_cnt == (RND_LAT-1);
    assign rst_rnd_cnt = (buffer_full & pre_process_rnd) | rst | ctrl_feed;

    dff #(.SIZE(CNT_SIZE),.ASYN(0))   
    rnd_cnt_reg(
        .clk(clk),
        .rst(rst_rnd_cnt),
        .d(next_rnd_cnt),
        .en(glob_enable),
        .q(rnd_cnt)
    );
  
    assign rnd_valid_next_enable = (((rnd_cnt == (RND_LAT-2)) & glob_enable & ~ctrl_feed) | (buffer_full & ~glob_enable)) & ~rst;
    assign rnd_out = {Q,rnd_buffer};

end
endgenerate


endmodule
