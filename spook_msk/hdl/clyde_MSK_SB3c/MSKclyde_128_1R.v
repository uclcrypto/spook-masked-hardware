/*
    Implements the logic for the masked Clyde primitive.
*/
(* fv_prop = "PINI", fv_strat = "composite", fv_order=d *)
module MSKclyde_128_1R #(
    // Number of masking shares
    parameter d = 2,
    // Ns - total number of 2 rounds steps needed ( in units of 1 x (32SBoxes + 2 LBoxes)).
    parameter Ns = 6,
    // Power (2**) Divider of the State for SBoxes - 
    // Divide the total amount of parallel sboxes 
    // by the corresponding power of 2:
    //  PDSBOX = 0 -> 32 // SBoxes, 
    //         = 1 -> 16, 
    //         = 2 -> 8, 
    //         = 3 -> 2, 
    //         = 5 -> 1.
    //
    // The SBoxes computation over the state are thus performed in 2**PDSBOX clock cycles
    parameter PDSBOX = 2,
    // Power (2**) Divider of the State for LBoxes - 
    // Divide the total amount of parallel Lboxes 
    // by the corresponding power of 2:
    //  PDLBOX = 0 -> 2, // LBoxes, 
    //         = 1 -> 1.
    //
    // The Lboxes computation over the state are thus performed in 2**PDLBOX clock cycles
    parameter PDLBOX = 1,
    // Number of state bits
    parameter Nbits = 128,
    // ALLOW_SPEED_ARCH:
    // 1: add bypass muxes to reduce the time of each round by one cycle
    // 0: keep the 'low_area' architecture.
    parameter ALLOW_SPEED_ARCH=0
)(
    clk,
    pre_syn_rst,
    inverse,
    data_in_valid,
    data_in,
    sharing_key,
    tweak,
    sharing_data_out,
    pre_sharing_data_out_valid,
    pre_enable,
    rnd1_SB,
    rnd2_SB,
    pre_pre_need_rnd1_SB,
    pre_need_rnd1_SB,
    pre_pre_need_rnd2_SB,
    pre_need_rnd2_SB,
    in_process_status
);

///////////////////////////////////////
// Generation parameters computation //
///////////////////////////////////////

`include "spook_sbox_rnd.inc"

// Amount of round to proceed
localparam R_AMOUNT = 2*Ns;

// Size of a sharing (in bits)
localparam SIZE_SHARING = d*Nbits;
// Actual SB divider - how many chuncks to serially process.
localparam SB_DIVIDER = 2**PDSBOX;
// Actual chunk size (if PDSBOX=0: 128, 1: 64, 2: 32, 3: 16 ...).
localparam SIZE_SB_CHUNK = SIZE_SHARING/SB_DIVIDER;

// Actual LB divider - how many chuncks to serially process.
localparam LB_DIVIDER = 2**PDLBOX;
// Actual chunk size (if PDLBOX=0: 128, 1: 64).
localparam SIZE_LB_CHUNK = SIZE_SHARING/LB_DIVIDER;

// The practical delay of the SB operation
localparam SB_LAT = spook_sbox_lat + SB_DIVIDER;
// The practical delay of the LB operation
localparam LB_LAT = LB_DIVIDER;

// Practical round latency (default: area architecture)
localparam R_AREA_LAT = SB_LAT + LB_LAT; 
localparam R_SPEED_LAT = R_AREA_LAT - 1;
localparam R_LAT = ALLOW_SPEED_ARCH ? R_SPEED_LAT : R_AREA_LAT;
// Latency of a full run
localparam clyde_latency= R_AMOUNT*R_LAT;

// The size of the masking counter iterator (main counter of the design)
parameter SIZE_MASK_CNT = $clog2(R_LAT) + 1;
// The size of the rounds iterator - used for a counter.
parameter SIZE_R_CNT = (R_AMOUNT % 2 == 0) ? $clog2(R_AMOUNT) : $clog2(R_AMOUNT) + 1;

// Size of each randomness bus (in bits)
localparam SIZE_SB_RND = (spook_sbox_rnd*32/SB_DIVIDER)/2;

(* fv_type="clock" *) 
input clk;
(* fv_type="control" *)
input pre_syn_rst;
(* fv_type="control" *) 
input data_in_valid;
(* fv_type="control" *) 
input inverse;
(* fv_type="control" *) 
input [Nbits-1:0] data_in /*verilator public*/;
(* fv_type="sharing", fv_latency=0, fv_count=Nbits *) 
input [d*Nbits-1:0] sharing_key /*verilator public*/;
(* fv_type="control"*) 
input [Nbits-1:0] tweak;
(* fv_type="sharing", fv_latency=clyde_latency, fv_count=Nbits *)
output [d*Nbits-1:0] sharing_data_out;
(* fv_type="control" *) 
output pre_sharing_data_out_valid;
(* fv_type="control" *)
input pre_enable;
(* fv_type="random", fv_count=0 *) 
input [SIZE_SB_RND-1:0] rnd1_SB /*verilator public*/;
(* fv_type="random", fv_count=0 *) 
input [SIZE_SB_RND-1:0] rnd2_SB;
(* fv_type="control" *) 
output pre_pre_need_rnd1_SB;
(* fv_type="control" *) 
output pre_need_rnd1_SB;
(* fv_type="control" *) 
output pre_pre_need_rnd2_SB;
(* fv_type="control" *) 
output pre_need_rnd2_SB;
(* fv_type="control" *)
output in_process_status;

//////////////////////////
// General Architecture //
//////////////////////////

// Global reset and pre_enable signal
reg syn_rst;
always@(posedge clk)
    syn_rst <= pre_syn_rst;

////// GENERAL DATAPATH //////
// phi unit //////////
wire enable_phi;
wire [127:0] delta_TWK;
phi_unit_dual
phi_unit_core(
    .clk(clk),
    .phi_in(tweak),
    .phi_in_valid(data_in_valid),
    .inverse(inverse),
    .phi_out(delta_TWK),
    .enable(enable_phi)
);

// W unit ////////////
wire enable_W;
wire [3:0] W;
Wsel_lfsr_dual
Wsel_core(
    .clk(clk),
    .syn_init(data_in_valid),
    .inverse(inverse),
    .Wout(W),
    .enable(enable_W)
);

// Sbox unit /////////////
// Data representation bundle2cols //
wire [SIZE_SHARING-1:0] sharing_bundle_to_SB, sharing_cols_to_SB;
MSKbundle2cols #(.d(d),.Nbits(Nbits))
sh_b2c_sb(
    .bundle_in(sharing_bundle_to_SB),
    .cols(sharing_cols_to_SB)
);

// zero sharing //
localparam SIZE_CHUNK_COLS = Nbits/SB_DIVIDER;
(* KEEP = "TRUE", S = "TRUE", DONT_TOUCH = "TRUE" *)
wire [SIZE_SB_CHUNK-1:0] sharing_cols_chunk_zero;
cst_mask #(.d(d),.count(SIZE_CHUNK_COLS))
cst_cols_SB_0(
    .cst({SIZE_CHUNK_COLS{1'b0}}),
    .out(sharing_cols_chunk_zero)
);

// Feeding SB mux //
(* KEEP = "TRUE", S = "TRUE", DONT_TOUCH = "TRUE" *)
wire [SIZE_SB_CHUNK-1:0] sharing_cols_chunk_to_SB;
wire ctrl_enable_feed_SB;
MSKmux_par #(.d(d),.count(SIZE_CHUNK_COLS))
mux_sh_barrier_to_SB(
    .sel(ctrl_enable_feed_SB),
    .in_true(sharing_cols_to_SB[0 +: SIZE_SB_CHUNK]),
    .in_false(sharing_cols_chunk_zero),
    .out(sharing_cols_chunk_to_SB)
);

// Shared columns chunk going to the SB unit //
wire [SIZE_SB_CHUNK-1:0] sharing_cols_chunk_from_SB;
wire enable_SB;
MSKsbox_unit_dual #(.d(d),.Nbits(Nbits),.PDSBOX(PDSBOX))
SBOX_unit(
    .cols(sharing_cols_chunk_to_SB),
    .rnd1(rnd1_SB),
    .rnd2(rnd2_SB),
    .clk(clk),
    .inverse(inverse),
    .cols_post_sb(sharing_cols_chunk_from_SB),
    .enable(enable_SB)
);

// Reformatted sharing of the columns after the SB:
//     PDSBOX=0: full state post SB unit
//     PDSBOX>=0: shifted state fed with the chunk after the SB unit
wire [SIZE_SHARING-1:0] sharing_cols_from_SB;
generate
if(PDSBOX==0) begin
    assign sharing_cols_from_SB = sharing_cols_chunk_from_SB;
end else begin
    assign sharing_cols_from_SB = {sharing_cols_chunk_from_SB,sharing_cols_to_SB[SIZE_SB_CHUNK +: SIZE_SHARING-SIZE_SB_CHUNK]};
end
endgenerate

// Data representation cols2bundle //
wire [SIZE_SHARING-1:0] sharing_bundle_from_SB;
MSKcols2bundle #(.d(d),.Nbits(Nbits))
sh_c2b_sb(
    .cols(sharing_cols_from_SB),
    .bundle_out(sharing_bundle_from_SB)
);

// Lbox unit /////////////
wire [SIZE_SHARING-1:0] sharing_bundle_to_LB;

// zero sharing //
localparam SIZE_CHUNK_BUNDLE = Nbits/LB_DIVIDER;
(* KEEP = "TRUE", S = "TRUE", DONT_TOUCH = "TRUE" *)
wire [SIZE_LB_CHUNK-1:0] sharing_bundle_chunk_zero;
cst_mask #(.d(d),.count(SIZE_CHUNK_BUNDLE))
cst_bundle_LB_0(
    .cst({SIZE_CHUNK_BUNDLE{1'b0}}),
    .out(sharing_bundle_chunk_zero)
);

// Feeding LB mux //
(* KEEP = "TRUE", S = "TRUE", DONT_TOUCH = "TRUE" *)
wire [SIZE_LB_CHUNK-1:0] sharing_bundle_chunk_to_LB;
wire ctrl_enable_feed_LB;
MSKmux_par #(.d(d),.count(SIZE_CHUNK_BUNDLE))
mux_sh_barrier_to_LB(
    .sel(ctrl_enable_feed_LB),
    .in_true(sharing_bundle_to_LB[0 +: SIZE_LB_CHUNK]),
    .in_false(sharing_bundle_chunk_zero),
    .out(sharing_bundle_chunk_to_LB)
);

// LB logic //
wire [SIZE_LB_CHUNK-1:0] sharing_bundle_chunk_from_LB;
MSKlbox_unit_dual #(.d(d),.Nbits(Nbits),.PDLBOX(PDLBOX))
LBOX_unit(
    .bundle_in(sharing_bundle_chunk_to_LB),
    .bundle_out(sharing_bundle_chunk_from_LB),
    .inverse(inverse)
);

// Reformatted sharing of the columns after the SB:
//     PDSBOX=0: full state post SB unit
//     PDSBOX>=0: shifted state fed with the chunk after the SB unit
wire [SIZE_SHARING-1:0] sharing_bundle_from_LB;
generate
if(PDLBOX==0) begin
    assign sharing_bundle_from_LB = sharing_bundle_chunk_from_LB;
end else begin
    assign sharing_bundle_from_LB = {sharing_bundle_chunk_from_LB,sharing_bundle_to_LB[SIZE_LB_CHUNK +: SIZE_SHARING-SIZE_LB_CHUNK]};
end
endgenerate

// PT/CT sharing //////////////////
wire [SIZE_SHARING-1:0] sharing_bundle_data_in;
cst_mask #(.d(d),.count(Nbits))
sh_d_in(
    .cst(data_in),
    .out(sharing_bundle_data_in)
);

// Mode mux selection //////////////////
wire [SIZE_SHARING-1:0] sharing_bundle_feedback; 
wire ctrl_feedb_SB;
MSKmux_par #(.d(d),.count(Nbits))
mux_feedb(
    .sel(ctrl_feedb_SB),
    .in_true(sharing_bundle_from_SB),
    .in_false(sharing_bundle_from_LB),
    .out(sharing_bundle_feedback)
);

// W/TK Addition unit //////////////   
wire [SIZE_SHARING-1:0] sharing_bundle_to_WTKadd, sharing_bundle_from_WTKadd /*verilator public*/;
wire ctrl_W_addition;
wire ctrl_TK_addition;
MSKaddWTK #(.d(d),.Nbits(Nbits))
addition_unit(
    .sharing_bundle_in(sharing_bundle_to_WTKadd),
    .sharing_K(sharing_key),
    .W(W),
    .delta(delta_TWK),
    .ctrl_W_addition(ctrl_W_addition),
    .ctrl_TK_addition(ctrl_TK_addition),
    .sharing_bundle_out(sharing_bundle_from_WTKadd)
);

// Pre W/TK addition mux /////////////////// 
wire [SIZE_SHARING-1:0] sharing_bundle_feeding;
MSKmux_par #(.d(d),.count(Nbits))
mux_feeding(
    .sel(data_in_valid),
    .in_true(sharing_bundle_data_in),
    .in_false(sharing_bundle_feedback),
    .out(sharing_bundle_to_WTKadd)
);

// State register /////////////////////////
wire [SIZE_SHARING-1:0] sharing_bundle_state /*verilator public*/;
wire enable_state;
MSKregEn_par #(.d(d),.count(Nbits))
state_reg(
    .clk(clk),
    .rst(1'b0),
    .en(enable_state),
    .in(sharing_bundle_from_WTKadd),
    .out(sharing_bundle_state)
);

// Output mux ////////////////////////////
(* KEEP = "TRUE", S = "TRUE", DONT_TOUCH = "TRUE" *)
wire [SIZE_SHARING-1:0] cst_sharing_zero; 
cst_mask #(.d(d),.count(Nbits))
cst_zero_out(
    .cst({Nbits{1'b0}}),
    .out(cst_sharing_zero)
);

wire ctrl_mux_out;
MSKmux_par #(.d(d),.count(Nbits))
mux_sh_out(
    .sel(ctrl_mux_out),
    .in_true(sharing_bundle_state),
    .in_false(cst_sharing_zero),
    .out(sharing_data_out)
);

///////// GENERAL CONTROL ///////////////
// Out data validity signal /////
wire enable_pre_valid_out;
wire syn_rst_pre_valid_out;
wire next_pre_valid_out;

dff #(.SIZE(1),.ASYN(0))
pre_valid_out(
    .clk(clk),
    .rst(syn_rst_pre_valid_out),
    .d(next_pre_valid_out),
    .en(enable_pre_valid_out),
    .q(pre_sharing_data_out_valid)
);

wire sharing_data_out_valid;

dff #(.SIZE(1),.ASYN(0))
valid_out(
    .clk(clk),
    .rst(syn_rst_pre_valid_out),
    .d(pre_sharing_data_out_valid),
    .en(enable_pre_valid_out),
    .q(sharing_data_out_valid)
);

// In process flag //
wire flag_in_process;
wire next_flag_in_process = data_in_valid | flag_in_process;
wire enable_flag_in_process;
wire syn_rst_flag_in_process;

dff #(.SIZE(1),.ASYN(0))
in_process_reg(
    .clk(clk),
    .rst(syn_rst_flag_in_process),
    .d(next_flag_in_process),
    .en(enable_flag_in_process),
    .q(flag_in_process)
);

assign in_process_status = flag_in_process;

// Masking counter //
wire [SIZE_MASK_CNT-1:0] mask_cnt;
wire [SIZE_MASK_CNT-1:0] next_mask_cnt = mask_cnt + 1'b1;
wire enable_mask_cnt;
wire syn_rst_mask_cnt;

dff #(.SIZE(SIZE_MASK_CNT),.ASYN(0))
mask_cnt_reg(
    .clk(clk),
    .rst(syn_rst_mask_cnt),
    .d(next_mask_cnt),
    .en(enable_mask_cnt),
    .q(mask_cnt)
);

// Round counter //
wire [SIZE_R_CNT-1:0] r_cnt;
wire [SIZE_R_CNT-1:0] next_r_cnt = r_cnt + 1'b1; 
wire enable_r_cnt;
wire syn_rst_r_cnt;

dff #(.SIZE(SIZE_R_CNT),.ASYN(0))
r_cnt_reg(
    .clk(clk),
    .rst(syn_rst_r_cnt),
    .d(next_r_cnt),
    .en(enable_r_cnt),
    .q(r_cnt)
);


////////////// CONTROL ///////////////////
///// Status flags /////
// The next pre_enable could start the process for a new run
wire pre_rst_run = ~flag_in_process & ~next_flag_in_process;
// End of a round computation
wire end_r_computation = (mask_cnt == R_LAT-1);
// The round counter should be increased at the next clock cycle
wire pre_end_r_computation = (mask_cnt == R_LAT-2); 
// Last round 
wire last_round = (r_cnt == R_AMOUNT-1);
// Last clock cycle of the run
wire end_process = end_r_computation & last_round; //(r_cnt == R_AMOUNT-1);
// The next clock cycle is the last one of the run
wire pre_end_process = pre_end_r_computation & last_round; //(r_cnt == R_AMOUNT-1);

///// Control for the masking counter /////
wire pre_en_mask_cnt = pre_syn_rst | pre_enable;
reg en_mask_cnt;
always@(posedge clk)
    en_mask_cnt <= pre_en_mask_cnt;

assign enable_mask_cnt = en_mask_cnt;
assign syn_rst_mask_cnt = syn_rst | ~flag_in_process | end_r_computation ;

///// Control for the in process flag /////
assign enable_flag_in_process = en_mask_cnt;
assign syn_rst_flag_in_process = syn_rst | pre_sharing_data_out_valid;

///// Control for the validity flag /////
assign next_pre_valid_out = pre_end_process;
assign enable_pre_valid_out = en_mask_cnt;
assign syn_rst_pre_valid_out = syn_rst;

///// Control for the state register and the SBOXes /////
wire pre_en_state = pre_enable;
reg en_state_reg;
always@(posedge clk)
    en_state_reg <= pre_en_state;

assign enable_state = en_state_reg;
assign enable_SB = en_state_reg;

///// Control for the round counter /////
wire pre_en_r_cnt = pre_syn_rst | (pre_rst_run | pre_end_r_computation) & pre_enable;
reg en_r_cnt;
always@(posedge clk)
    en_r_cnt <= pre_en_r_cnt;

assign enable_r_cnt = en_r_cnt;
assign syn_rst_r_cnt = syn_rst | ~flag_in_process;

///// Control for the W unit /////
assign enable_W = en_r_cnt;

///// Control for the TK unit ///// 
wire pre_en_TK = pre_rst_run | (pre_en_r_cnt & r_cnt[0]); 
reg en_TK;
always@(posedge clk)
    en_TK <= pre_en_TK;

assign enable_phi = en_TK;

///// Control for the W/TK addition /////
assign ctrl_W_addition = inverse ? data_in_valid | (end_r_computation & ~end_process) : end_r_computation;
assign ctrl_TK_addition = data_in_valid | (end_r_computation & r_cnt[0]);

///// Control for output mux /////
assign ctrl_mux_out = sharing_data_out_valid;

///// Control for the randomness handling /////
// Pre need rnd1 //
wire pre_need_rnd1_SB_ENC; 
wire pre_need_rnd1_SB_DEC;

wire pre_need_rnd1_SB = inverse ? pre_need_rnd1_SB_DEC : pre_need_rnd1_SB_ENC;

wire pre_need_rnd2_SB_ENC; 
wire pre_need_rnd2_SB_DEC;

wire pre_need_rnd2_SB = inverse ? pre_need_rnd2_SB_DEC : pre_need_rnd2_SB_ENC;

// DEBUG //
wire pre_pre_need_rnd1_SB_ENC;
wire pre_pre_need_rnd2_SB_ENC;
wire pre_pre_need_rnd1_SB_DEC;
wire pre_pre_need_rnd2_SB_DEC;
assign pre_pre_need_rnd1_SB = inverse ? pre_pre_need_rnd1_SB_DEC : pre_pre_need_rnd1_SB_ENC;
assign pre_pre_need_rnd2_SB = inverse ? pre_pre_need_rnd2_SB_DEC : pre_pre_need_rnd2_SB_ENC;


generate
if(SB_DIVIDER==1) begin
    assign pre_need_rnd1_SB_ENC = flag_in_process ? (end_r_computation & ~end_process) : 1'b1;
    assign pre_need_rnd2_SB_ENC = flag_in_process ? (mask_cnt==0) & en_mask_cnt: 1'b0;

    //
    assign pre_pre_need_rnd1_SB_ENC = flag_in_process ? (pre_end_r_computation &  ~last_round) : 1'b1; 
    assign pre_pre_need_rnd2_SB_ENC = flag_in_process ? (end_r_computation &  ~last_round) : 1'b1; 

end else begin
    assign pre_need_rnd1_SB_ENC = flag_in_process ? ((end_r_computation & ~end_process) | (mask_cnt < SB_DIVIDER-1)) : 1'b1;
    assign pre_need_rnd2_SB_ENC = flag_in_process ? (mask_cnt < SB_DIVIDER) : 1'b0;

    //
    assign pre_pre_need_rnd1_SB_ENC = flag_in_process ? ((pre_end_r_computation | end_r_computation) & ~last_round) | (mask_cnt < SB_DIVIDER-2) : 1'b1;
    assign pre_pre_need_rnd2_SB_ENC = flag_in_process ? (mask_cnt < SB_DIVIDER-1) | (end_r_computation & ~last_round) : 1'b1; 
end
endgenerate

/////// ARCHITECTURE DEPENDENT CIRCUITRY /////////////
generate
if(ALLOW_SPEED_ARCH) begin
    // Add bypass mux to the datapath // 
    // Sharing to SB //
    wire ctrl_feed_SB_from_state;
    MSKmux_par #(.d(d),.count(Nbits))
    mux_sh_to_SB(
        .sel(ctrl_feed_SB_from_state),
        .in_true(sharing_bundle_state),
        .in_false(sharing_bundle_from_LB),
        .out(sharing_bundle_to_SB)
    );
   
    // Sharing to LB //
    wire ctrl_feed_LB_from_state;
    MSKmux_par #(.d(d),.count(Nbits))
    mux_sh_to_LB(
        .sel(ctrl_feed_LB_from_state),
        .in_true(sharing_bundle_state),
        .in_false(sharing_bundle_from_SB),
        .out(sharing_bundle_to_LB)
    );

    // Control for datapath muxes //
    assign ctrl_feed_SB_from_state = inverse ? (mask_cnt >= LB_LAT) : (mask_cnt < SB_LAT);
    assign ctrl_feed_LB_from_state = inverse ? (mask_cnt < LB_LAT) : (mask_cnt >= SB_LAT);
    assign ctrl_feedb_SB = inverse ? (mask_cnt >= LB_LAT-1) : (mask_cnt < SB_LAT-1);
    assign ctrl_enable_feed_SB = inverse ? (mask_cnt >= LB_LAT - 1) : (mask_cnt < SB_DIVIDER);
    assign ctrl_enable_feed_LB = inverse ? (mask_cnt < LB_LAT) : (mask_cnt >= SB_DIVIDER-1);

    if(LB_DIVIDER==1) begin
        assign pre_need_rnd1_SB_DEC = pre_need_rnd1_SB_ENC; 
        assign pre_need_rnd2_SB_DEC = pre_need_rnd2_SB_ENC; 
        //
        assign pre_pre_need_rnd1_SB_DEC = flag_in_process ? (mask_cnt < SB_DIVIDER-2) | ((pre_end_r_computation | end_r_computation) & ~last_round): 1'b1;
        assign pre_pre_need_rnd2_SB_DEC = flag_in_process ? (mask_cnt<SB_DIVIDER-1) | (end_r_computation & ~last_round): 1'b1;
    end else begin
        assign pre_need_rnd1_SB_DEC = flag_in_process & (mask_cnt<SB_DIVIDER); 
        assign pre_need_rnd2_SB_DEC = flag_in_process & (mask_cnt-1<SB_DIVIDER) & (mask_cnt>0) ; 
        // 
        assign pre_pre_need_rnd1_SB_DEC = flag_in_process ? (mask_cnt<SB_DIVIDER-1) | (end_r_computation & ~last_round): 1'b1;
        assign pre_pre_need_rnd2_SB_DEC = flag_in_process & (mask_cnt<SB_DIVIDER); 
    end

end else begin
    // Feeding value comes from the state
    assign sharing_bundle_to_SB = sharing_bundle_state;
    assign sharing_bundle_to_LB = sharing_bundle_state;

    // Control for datapath muxes //
    assign ctrl_feedb_SB = inverse ? (mask_cnt >= LB_LAT) : (mask_cnt < SB_LAT);
    assign ctrl_enable_feed_SB = inverse ? (mask_cnt >= LB_LAT) : (mask_cnt < SB_DIVIDER);
    assign ctrl_enable_feed_LB = inverse ? (mask_cnt < LB_LAT) : (mask_cnt >= SB_DIVIDER); 

    if(LB_DIVIDER==1) begin
        assign pre_need_rnd1_SB_DEC = flag_in_process & (mask_cnt<SB_DIVIDER); 
        assign pre_need_rnd2_SB_DEC = flag_in_process & (mask_cnt-1<SB_DIVIDER) & (mask_cnt>0); 
        //
        assign pre_pre_need_rnd1_SB_DEC = flag_in_process ? (mask_cnt < SB_DIVIDER-1) | (end_r_computation & ~last_round): 1'b1;
        assign pre_pre_need_rnd2_SB_DEC = flag_in_process & (mask_cnt < SB_DIVIDER) ;
    end else begin
        assign pre_need_rnd1_SB_DEC = flag_in_process & (mask_cnt-1<SB_DIVIDER); 
        assign pre_need_rnd2_SB_DEC = flag_in_process & (mask_cnt-2<SB_DIVIDER) & (mask_cnt>1) ; 
        //
        assign pre_pre_need_rnd1_SB_DEC = flag_in_process & (mask_cnt<SB_DIVIDER);
        assign pre_pre_need_rnd2_SB_DEC = flag_in_process & (mask_cnt-1<SB_DIVIDER) & (mask_cnt>0); 
    end

end
endgenerate


endmodule
