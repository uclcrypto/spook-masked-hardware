/*
    Controller for the module "blck_builder_dp".
*/
module blck_builder_cntrl
#
(
    parameter BUS_SIZE = 32, // [8,16,32] 
    parameter BLCK_SIZE = 256
)
(
    clk,
    rst,
    set_ready,
    ready,
    // Inputs control /////////////////////////////////
    // [True]: input data is valid
    data_in_valid,
    // [True]: valid input data is not of full bus length (only if BUS_SIZE>8)
    data_in_partial,
    // [True]: the data is the last to be processed  //TODO adapt for 1 then 1
    data_in_eot,
    // To datapath ////////////////////////////////////
    // General 
    flag_cnst_add_done,
    en_update,
    en_padding,
    // Output /////////////////////////////////////////
    blck_out_rdy
);

// Generation param
localparam BUSdiv8 = BUS_SIZE/8;
localparam BLCKdiv8 = BLCK_SIZE/8;

// IOs ports 
input clk;
input rst;
input set_ready;
output ready;
input data_in_valid; 
input data_in_partial; 
input data_in_eot; 
output flag_cnst_add_done;
output en_update;
output en_padding;
output blck_out_rdy;





// Control signal
wire nblock_full; // At the next rising edge, the block is full and ready to be processed

// FSM /////////////////
localparam  IDLE = 2'd0,
LOAD = 2'd1,
PAD  = 2'd2;

wire [1:0] state;
reg [1:0] next_state;


dff #(.SIZE(2),.ASYN(0),.RST_V(IDLE))
reg_state(
    .clk(clk),
    .rst(rst),
    .d(next_state),
    .en(1'b1),
    .q(state)
);

generate
always@(*)
case(state)
    IDLE: if(set_ready) begin
        next_state = LOAD;
    end else begin
        next_state = IDLE;
    end
    LOAD: if(data_in_valid) begin 
        if(nblock_full) begin
            next_state = IDLE;
        end else begin
            if(data_in_eot) begin
                next_state = PAD;
            end else begin
                next_state = LOAD;
            end
        end
    end else begin
        next_state = LOAD;
    end
    PAD: if(nblock_full) begin
        next_state = IDLE;
    end else begin
        next_state = PAD;
    end
    default: next_state = IDLE;
endcase
endgenerate

// Counter
localparam  BUS_LOAD_CNT = (BLCK_SIZE/BUS_SIZE);
parameter SIZE_LOAD_CNT = $clog2(BUS_LOAD_CNT)+1;
// byte counter for the processed block
wire [SIZE_LOAD_CNT-1:0] cnt_byte; 
// next value of the counter (at the rising edge of the clock)
wire [SIZE_LOAD_CNT-1:0] next_cnt_byte; 
// rst control signal of the clock
wire rst_cnt_byte; 
// enable control signal of the clock
wire en_cnt_byte; 

//assign next_cnt_byte = rst_cnt_byte ? 0 : (en_cnt_byte ? (cnt_byte[SIZE_LOAD_CNT-1:0] + 1'b1) : cnt_byte[SIZE_LOAD_CNT-1:0]);
assign next_cnt_byte = cnt_byte[SIZE_LOAD_CNT-1:0] + 1'b1;

dff #(.SIZE(SIZE_LOAD_CNT),.ASYN(0))
reg_cnt_byte(
    .clk(clk),
    .rst(rst | rst_cnt_byte),
    .d(next_cnt_byte),
    .en(en_cnt_byte),
    .q(cnt_byte)
);

// Block status flags //////////////////////////// 
// reset flags
wire syn_rst_flags;
assign syn_rst_flags = (state == IDLE) & (next_state == LOAD); 

// Padding control ///////////////////////////////
// [True]: the constant addition used for the padding has ben already added
wire f_cnst_add_done; 
wire set_f_add_done;

flag_core cnst_add_done(.clk(clk),
    .rst(rst),
    .syn_unset(syn_rst_flags),
    .syn_set(set_f_add_done),
    .flag(f_cnst_add_done)
);


// Control signal assign //////////////:
// Next enable signal for the buffer
wire current_state_load;
wire current_state_pad;

wire next_c_state_load = (next_state == LOAD);
wire next_c_state_pad = (next_state == PAD);

dff #(.SIZE(1),.ASYN(0))
c_load_reg(
    .clk(clk),
    .rst(rst),
    .d(next_c_state_load),
    .en(1'b1),
    .q(current_state_load)
);

dff #(.SIZE(1),.ASYN(0))
c_pad_reg(
    .clk(clk),
    .rst(rst),
    .d(next_c_state_pad),
    .en(1'b1),
    .q(current_state_pad)
);

// General 
assign nblock_full = (next_cnt_byte==(BLCK_SIZE/BUS_SIZE));
assign rst_cnt_byte = (state==IDLE);
assign en_cnt_byte = (current_state_load & data_in_valid) | current_state_pad;


// Parameter dependant
generate
if(BUSdiv8==1) begin
    assign set_f_add_done = (state == PAD);
end else begin
    assign set_f_add_done = (state == PAD) | ((state == LOAD) & data_in_valid & data_in_partial);
end
endgenerate

// Flag to allow blck_rdy outputting 
// (to avoid false blck_out_ready at the beginning)
wire allow_blck_rdy;

flag_core allw_blck_rdy(
    .clk(clk),
    .rst(rst),
    .syn_unset(1'b0),
    .syn_set(set_ready),
    .flag(allow_blck_rdy)
);

// Output 
assign flag_cnst_add_done = f_cnst_add_done;
assign en_update = en_cnt_byte;
assign en_padding = (state == PAD);

assign blck_out_rdy = (state == IDLE) & allow_blck_rdy;
assign ready = (state == LOAD);
endmodule
