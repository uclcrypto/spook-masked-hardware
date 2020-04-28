/* 
    Main controller module of the spook algorithm
*/
module spook_cntrl
(
    input clk,
    input rst,
    // Decoder //////////////////////////////
    input instruction_valid,
    input header_valid,
    input data_in_valid, 

    output rdy_instr_fetch,
    output rdy_head_fetch,
    output rdy_data_fetch,
    // Instruction related
    input decrypt,
    input key_update,
    input key_only,
    input seed_update,
    // Header related
    input dec_seg_empty,
    input [3:0] dec_dtype,
    input dec_eot,
    input dec_eoi,
    input [15:0] dec_length,
    input [3:0] dec_sel_nibble,
    // Data related 
    input data_in_last_of_seg,

    // Datapath ////////////////////////////////
    output to_dp_ctrl_mux_tag_computation,
    output to_dp_initialisation,
    output to_dp_ctrl_en_tag_verif,
    input from_dp_tag_is_valid,

    output to_dp_keyh_enable_feeding,
    output to_dp_keyh_rst,
    output to_dp_keyh_n_lock_for_seed,
    output to_dp_keyh_feed_prng,
    input from_dp_keyh_rdy_refresh,
    output to_dp_keyh_start_refresh,

    output to_dp_NTh_enable_feeding,

    output to_dp_shad_pre_rst,
    output to_dp_shad_pre_enable,
    output to_dp_shad_dig_decryption,
    output to_dp_shad_dig_first_M,
    input from_dp_shad_pre_done,
    input from_dp_shad_release_dig,

    output to_dp_clyde_inverse,
    output to_dp_clyde_pre_data_in_valid,
    input from_dp_clyde_pre_data_out_valid,
    output to_dp_clyde_pre_enable,
    output to_dp_clyde_en_feeding_prng1,
    output to_dp_clyde_en_feeding_prng2,
    input from_dp_clyde_ready_start, 

    // Blck buider controller ////////////////
    input dig_blck_ready,
    input ready_ext_blck_builder,

    output blck_bld_data_in_eot,
    output blck_bld_set_ready,
    // Encoder //////////////////
    output [3:0] encod_dtype,
    output encod_eot,
    output encod_eoi,
    output encod_last,
    output [15:0] encod_length,

    output encod_status_sel,
    output encod_pre_send_header,
    output encod_send_header,
    output encod_pre_send_status,
    output encod_send_status,
    output encod_pre_send_tag,
    output encod_send_tag,
    output encod_unlock_dig_process,
    input encod_pre_ready,
    input encod_ready,
    input encod_release_buffer,
    output encod_pre_pre_send_dig_data,
    output encod_pre_send_dig_data,
    output encod_send_dig_data
);


// Control signal reuiqred for the FSM
wire AD_digested; // All ADs have been digested (currently digesting PT or CT);
wire flag_data_last_of_seg;
wire flag_eot_seg_header_sent;
wire previous_flag_data_last_of_seg;
wire early_out_seg_header;

// FSM ///////////////
`include "states_constants.vh"

localparam  HDR_KEY = 4'b1100,
HDR_Npub = 4'b1101,
HDR_AD = 4'b0001,
HDR_CT = 4'b0101,
HDR_PT = 4'b0100,
HDR_TAG = 4'b1000,
HDR_SEED = 4'b1001;

// states registers
wire [4:0] state;
reg [4:0] nextstate;

dff #(.SIZE(5),.ASYN(0))
reg_state(
    .clk(clk),
    .rst(rst),
    .d(nextstate),
    .en(1'b1),
    .q(state)
);

// nextstate logic 
always@(*)
case(state)
    WAIT_INST: if(instruction_valid) begin
        if(key_update) begin
            nextstate = WAIT_KEY;
        end else if(seed_update) begin
            nextstate = WAIT_SEED;
        end else begin
            nextstate = WAIT_NONCE;
        end 
    end else begin
        nextstate = WAIT_INST;
    end
    WAIT_KEY: if(header_valid) begin
        if(dec_dtype == HDR_KEY) begin
            if(dec_seg_empty) begin
                nextstate = WAIT_OUT_FAILURE;
            end else begin
                nextstate = LOAD_KEY;
            end
        end else begin
            nextstate = WAIT_OUT_FAILURE;
        end
    end else begin
        nextstate = WAIT_KEY;
    end
    LOAD_KEY: if(data_in_valid) begin
        if(data_in_last_of_seg) begin
            if(dec_eot) begin
                if(key_only) begin
                    nextstate = WAIT_OUT_SUCCESS;
                end else begin
                    nextstate = WAIT_NONCE;
                end
            end else begin
                nextstate = WAIT_KEY;
            end
        end else begin
            nextstate = LOAD_KEY;
        end
    end else begin
        nextstate = LOAD_KEY;
    end
    WAIT_SEED: if(header_valid) begin
        if(dec_dtype == HDR_SEED) begin
            if(dec_seg_empty) begin
                nextstate = WAIT_OUT_FAILURE;
            end else begin
                nextstate = LOAD_SEED;
            end
        end else begin
            nextstate = WAIT_OUT_FAILURE;
        end
    end else begin
        nextstate = WAIT_SEED;
    end
    LOAD_SEED: if(data_in_valid) begin
        if(data_in_last_of_seg) begin
            if(dec_eot) begin
                nextstate = WAIT_OUT_SUCCESS;
            end else begin
                nextstate = WAIT_KEY;
            end
        end else begin
            nextstate = LOAD_SEED;
        end
    end else begin
        nextstate = LOAD_SEED;
    end
    WAIT_NONCE: if(header_valid) begin
        if(dec_dtype == HDR_Npub) begin
            if(dec_seg_empty) begin
                nextstate = WAIT_OUT_FAILURE;
            end else begin
                nextstate = LOAD_NONCE;
            end
        end else begin
            nextstate = WAIT_OUT_FAILURE;
        end
    end else begin
        nextstate = WAIT_NONCE;
    end
    LOAD_NONCE: if(data_in_valid) begin
        if(data_in_last_of_seg) begin
            if(dec_eot) begin
                nextstate = START_CMP_B;
            end else begin
                nextstate = WAIT_NONCE;
            end
        end else begin
            nextstate = LOAD_NONCE;
        end
    end else begin
        nextstate = LOAD_NONCE;
    end
    START_CMP_B: nextstate = WAIT_CMP_B;
    WAIT_CMP_B: if(from_dp_clyde_pre_data_out_valid) begin
        nextstate = WAIT_FIRST;
    end else begin
        nextstate = WAIT_CMP_B;
    end
    WAIT_FIRST: if(from_dp_shad_pre_done) begin
        nextstate = WAIT_REFRESH_INIT;
    end else begin
        nextstate = WAIT_FIRST; 
    end
    WAIT_REFRESH_INIT: if(from_dp_keyh_rdy_refresh) begin
        nextstate = WAIT_D;
    end else begin
        nextstate = WAIT_REFRESH_INIT;
    end
    WAIT_D: if(header_valid) begin
        if(AD_digested) begin
            if(decrypt) begin
                if(dec_dtype == HDR_CT) begin
                    if(dec_seg_empty) begin
                        nextstate = WAIT_OUT_HEAD_D_EMPTY;
                    end else begin
                        nextstate = LOAD_D;
                    end
                end else begin
                    nextstate = WAIT_OUT_FAILURE;
                end
            end else begin    
                if(dec_dtype == HDR_PT) begin
                    if(dec_seg_empty) begin
                        nextstate = WAIT_OUT_HEAD_D_EMPTY;
                    end else begin
                        nextstate = LOAD_D;
                    end
                end else begin
                    nextstate = WAIT_OUT_FAILURE;
                end
            end
        end else begin
            if(dec_dtype == HDR_AD) begin
                if(dec_seg_empty) begin
                    nextstate = UPDATE_DIG_MODE;
                end else begin
                    nextstate = LOAD_D;
                end
            end else begin
                nextstate = WAIT_OUT_FAILURE;
            end
        end
    end else begin
        nextstate = WAIT_D;
    end
    WAIT_OUT_HEAD_D_EMPTY: if(encod_ready) begin
        if(decrypt) begin
            nextstate = WAIT_TAG;
        end else begin
            nextstate = PREPARE_TAG_CMP;
        end
    end else begin
        nextstate = WAIT_OUT_HEAD_D_EMPTY;
    end
    LOAD_D: if(dig_blck_ready) begin
        if(AD_digested) begin
            if(~flag_eot_seg_header_sent) begin
                nextstate = WAIT_OUT_HEAD_D;
            end else begin
                nextstate = START_DIG_D;
            end
        end else begin
            nextstate = START_DIG_D;
        end
    end else begin
        if(flag_data_last_of_seg) begin
            if(dec_eot) begin
                nextstate = LOAD_D; // PADDING in progresss
            end else begin
                nextstate = WAIT_D; // New segment required
            end
        end else begin
            nextstate = LOAD_D;
        end
    end
    WAIT_OUT_HEAD_D: if(encod_ready) begin
        nextstate = WAIT_OUT_D;
    end else begin
        nextstate = WAIT_OUT_HEAD_D;
    end 
    WAIT_OUT_D: if(encod_ready) begin
        nextstate = START_DIG_D;
    end else begin
        nextstate = WAIT_OUT_D;
    end
    START_DIG_D: if(AD_digested) begin
        if(encod_ready | encod_pre_ready) begin 
            nextstate = WAIT_DIG_D;
        end else begin
            nextstate = START_DIG_D;
        end
    end else begin
        nextstate = WAIT_DIG_D;
    end
    WAIT_DIG_D: if(from_dp_shad_pre_done) begin 
        if(previous_flag_data_last_of_seg) begin 
            if(dec_eot) begin
                if(AD_digested) begin
                    if(decrypt) begin
                        nextstate = WAIT_TAG;
                    end else begin
                        nextstate = PREPARE_TAG_CMP;
                    end
                end else begin
                    nextstate = UPDATE_DIG_MODE;
                end
            end else begin
                nextstate = WAIT_D;
            end
        end else begin
            nextstate = LOAD_D;
        end
    end else begin
        nextstate = WAIT_DIG_D;
    end
    UPDATE_DIG_MODE: nextstate = WAIT_D;
    PREPARE_TAG_CMP: nextstate = WAIT_TAG_CMP;
    WAIT_TAG_CMP: if(from_dp_clyde_pre_data_out_valid) begin
        if(decrypt) begin
            nextstate = RESULT_TAG;
        end else begin
            nextstate = WAIT_OUT_HEAD_TAG;
        end
    end else begin
        nextstate = WAIT_TAG_CMP;
    end
    WAIT_OUT_HEAD_TAG: if(encod_ready) begin
        nextstate = WAIT_OUT_TAG;
    end else begin
        nextstate = WAIT_OUT_HEAD_TAG;
    end
    WAIT_OUT_TAG: if(encod_ready) begin
        nextstate = WAIT_OUT_SUCCESS;
    end else begin
        nextstate = WAIT_OUT_TAG;
    end
    WAIT_TAG: if(header_valid) begin
        if(dec_dtype == HDR_TAG) begin
            if(dec_seg_empty) begin
                nextstate = WAIT_OUT_FAILURE;
            end else begin
                nextstate = LOAD_TAG;
            end
        end else begin
            nextstate = WAIT_OUT_FAILURE;
        end
    end else begin
        nextstate = WAIT_TAG;
    end 
    LOAD_TAG: if(data_in_valid) begin
        if(data_in_last_of_seg) begin
            if(dec_eot) begin
                nextstate = PREPARE_TAG_CMP;
            end else begin
                nextstate = WAIT_TAG;
            end
        end else begin
            nextstate = LOAD_TAG;
        end
    end else begin
        nextstate = LOAD_TAG;
    end
    RESULT_TAG: if(from_dp_tag_is_valid) begin
        nextstate = WAIT_OUT_SUCCESS;
    end else begin
        nextstate = WAIT_OUT_FAILURE;
    end
    WAIT_OUT_SUCCESS: if(encod_ready) begin
        if(key_only | seed_update) begin
            nextstate = WAIT_INST;
        end else begin
            nextstate = WAIT_REFRESH_END;
        end
    end else begin
        nextstate = WAIT_OUT_SUCCESS;
    end
    WAIT_OUT_FAILURE: if(encod_ready) begin
        if(key_only | seed_update) begin
            nextstate = WAIT_INST;
        end else begin
            nextstate = WAIT_REFRESH_END;
        end
    end else begin
        nextstate = WAIT_OUT_FAILURE;
    end
    WAIT_REFRESH_END: if(from_dp_keyh_rdy_refresh) begin
        nextstate = WAIT_INST;
    end else begin
        nextstate = WAIT_REFRESH_END;
    end
    default: nextstate = WAIT_INST;
endcase



// Flags /////////////////////////
wire rst_flags;
assign rst_flags = (state == WAIT_INST);

// Data last
wire set_data_last;
wire unset_data_last;
flag_core last_f( 
    .clk(clk),
    .rst(rst),
    .syn_set(set_data_last),
    .syn_unset(unset_data_last),
    .flag(flag_data_last_of_seg)
);

assign set_data_last = data_in_last_of_seg;
assign unset_data_last = rst_flags | (state == WAIT_D);

wire en_prev_flag_last = set_data_last | ((state == START_DIG_D) & (nextstate == WAIT_DIG_D));
dff #(.SIZE(1),.ASYN(0))
reg_p_f_last(
    .clk(clk),
    .rst(rst),
    .d(flag_data_last_of_seg),
    .en(en_prev_flag_last),
    .q(previous_flag_data_last_of_seg)
);

// AD digested 
wire set_AD_digested;
flag_core 
AD_dig( 
    .clk(clk),
    .rst(rst),
    .syn_set(set_AD_digested),
    .syn_unset(rst_flags),
    .flag(AD_digested)
);

assign set_AD_digested = (state == UPDATE_DIG_MODE);

// First message digested
wire flag_first_m_done;
wire set_flag_first_m_done;
flag_core 
f_first_m( 
    .clk(clk),
    .rst(rst),
    .syn_set(set_flag_first_m_done),
    .syn_unset(rst_flags),
    .flag(flag_first_m_done)
);

assign set_flag_first_m_done = AD_digested & (state == WAIT_DIG_D) & from_dp_shad_release_dig;

// First header of segment sent
wire set_flag_eot_seg_header_sent;
wire rst_flag_eot_seg_header_sent;

assign set_flag_eot_seg_header_sent = (state == WAIT_OUT_HEAD_D) & dec_eot;
assign rst_flag_eot_seg_header_sent = (state == UPDATE_DIG_MODE) | rst_flags;

flag_core 
f_fseg_head(
    .clk(clk),
    .rst(rst),
    .syn_set(set_flag_eot_seg_header_sent),
    .syn_unset(rst_flag_eot_seg_header_sent),
    .flag(flag_eot_seg_header_sent)
);

// Flag digestion buffer released 
wire flag_dig_buffer_released;
wire set_flag_dig_buffer_released = (state == WAIT_DIG_D) & from_dp_shad_release_dig;
wire rst_flag_dig_buffer_released = (state == LOAD_D);

flag_core 
f_digb_rel(
    .clk(clk),
    .rst(rst),
    .syn_set(set_flag_dig_buffer_released),
    .syn_unset(rst_flag_dig_buffer_released),
    .flag(flag_dig_buffer_released)
);

// To decoder ///////////////////


assign rdy_instr_fetch = (state == WAIT_INST);
assign rdy_head_fetch = (state == WAIT_KEY) | 
(state == WAIT_NONCE) | 
(state == WAIT_D) | 
(state == WAIT_TAG) |
(state == WAIT_SEED);

assign rdy_data_fetch = (state == LOAD_NONCE) | 
(state == LOAD_KEY) | 
(state == LOAD_TAG) |
(state == LOAD_SEED) |
(ready_ext_blck_builder & ~(flag_data_last_of_seg) & 
    ( 
        (state == LOAD_D)|
        (state == WAIT_OUT_D)|
        ((state == WAIT_DIG_D) & flag_dig_buffer_released)
    ) 
);

// To datapath /////////////
assign to_dp_ctrl_mux_tag_computation = ((state == PREPARE_TAG_CMP) | (state == WAIT_TAG_CMP)) & ~decrypt; 
assign to_dp_initialisation = (state == START_CMP_B) | (state == WAIT_CMP_B) | (state == WAIT_FIRST); 
assign to_dp_ctrl_en_tag_verif = (state == RESULT_TAG);

assign to_dp_keyh_enable_feeding = ((state == LOAD_KEY) | ((dec_sel_nibble == 4'd0) & (state == LOAD_SEED)))& data_in_valid;
assign to_dp_keyh_rst = rst;  
assign to_dp_keyh_n_lock_for_seed = ~((dec_sel_nibble == 4'd0) & (state == LOAD_SEED));
assign to_dp_keyh_feed_prng = (dec_sel_nibble == 4'd0) & (state == LOAD_SEED) & data_in_valid;
assign to_dp_keyh_start_refresh = ((state == WAIT_REFRESH_INIT) | (state == WAIT_REFRESH_END)) & from_dp_keyh_rdy_refresh;

assign to_dp_NTh_enable_feeding = ((state == LOAD_NONCE) | (state == LOAD_TAG)) & data_in_valid;

assign to_dp_shad_pre_rst = (state == WAIT_INST) & (nextstate == WAIT_INST);
assign to_dp_shad_pre_enable = (((state == WAIT_CMP_B) & (nextstate == WAIT_FIRST)) |
(state == WAIT_FIRST) |
((state == START_DIG_D) & (nextstate != START_DIG_D) ) |
(state == WAIT_DIG_D)) & ~from_dp_shad_pre_done; 

assign to_dp_shad_dig_decryption = (((state == START_DIG_D) & (nextstate != START_DIG_D)) | (state == WAIT_DIG_D)) & decrypt & AD_digested;
assign to_dp_shad_dig_first_M = ~flag_first_m_done & AD_digested;  

assign to_dp_clyde_inverse = ((state == PREPARE_TAG_CMP) | (state == WAIT_TAG_CMP)) & decrypt;
assign to_dp_clyde_pre_data_in_valid = (state == START_CMP_B) | (state == PREPARE_TAG_CMP); 
assign to_dp_clyde_pre_enable = ((nextstate == START_CMP_B) | 
(state == WAIT_CMP_B) | 
(state == START_CMP_B) |
(state == LOAD_NONCE) |
(nextstate == PREPARE_TAG_CMP) |
(state == PREPARE_TAG_CMP) |
(state == WAIT_TAG_CMP)) & ~from_dp_clyde_pre_data_out_valid;

assign to_dp_clyde_en_feeding_prng1 = (dec_sel_nibble == 4'd1) & (state == LOAD_SEED) & data_in_valid;
assign to_dp_clyde_en_feeding_prng2 = (dec_sel_nibble == 4'd2) & (state == LOAD_SEED) & data_in_valid;

// Block builder control signals //////////

assign blck_bld_set_ready = (((state == WAIT_D)) & (nextstate == LOAD_D)) |
((state == WAIT_DIG_D) & ~(flag_data_last_of_seg) & from_dp_shad_release_dig);

assign blck_bld_data_in_eot = data_in_last_of_seg & dec_eot;

// Encoder control signals ////////// 
// Data length accumulation (management of uncontinous segments) //////////////
wire [15:0] len_accumulation_cnt;
wire [15:0] to_len_accumulation_cnt;
wire en_len_accumulation_cnt;
wire rst_len_accumulation_cnt;

wire len_accumulation_max = 16'h4;
wire len_accumulation_full = (len_accumulation_cnt == len_accumulation_max);

assign to_len_accumulation_cnt = rst_len_accumulation_cnt ? 16'b0 : len_accumulation_cnt + dec_length;

dff #(.SIZE(16),.ASYN(0)) 
len_accumul_cnt_reg( 
    .clk(clk), 
    .rst(rst),
    .d(to_len_accumulation_cnt),
    .en(en_len_accumulation_cnt),
    .q(len_accumulation_cnt)
);

assign rst_len_accumulation_cnt =  (nextstate == WAIT_OUT_D);
assign en_len_accumulation_cnt = ((state == WAIT_D) & header_valid & AD_digested) | rst_len_accumulation_cnt;

// Control signals to encoder //
assign encod_dtype = (state == WAIT_OUT_HEAD_TAG) ? HDR_TAG : (decrypt ? HDR_PT : HDR_CT);
assign encod_eot = dec_eot;
assign encod_eoi = dec_eoi;
assign encod_last = ((state == WAIT_OUT_HEAD_TAG) & ~decrypt) | (((state == WAIT_OUT_HEAD_D) | (state == WAIT_OUT_HEAD_D_EMPTY))  & decrypt & dec_eot & AD_digested);
assign encod_length = (state == WAIT_OUT_HEAD_TAG) ? 16'd16 : len_accumulation_cnt;

assign encod_send_header = (state == WAIT_OUT_HEAD_D) | (state == WAIT_OUT_HEAD_TAG) | (state == WAIT_OUT_HEAD_D_EMPTY);
assign encod_pre_send_header = ((nextstate == WAIT_OUT_HEAD_D) | (nextstate == WAIT_OUT_HEAD_TAG) | (nextstate == WAIT_OUT_HEAD_D_EMPTY));
assign encod_send_status = (state == WAIT_OUT_SUCCESS) | (state == WAIT_OUT_FAILURE);
assign encod_pre_send_status = ((nextstate == WAIT_OUT_SUCCESS) | (nextstate == WAIT_OUT_FAILURE));
assign encod_send_tag = (state == WAIT_OUT_TAG);
assign encod_pre_send_tag = (nextstate == WAIT_OUT_TAG);
assign encod_status_sel = (state == WAIT_OUT_FAILURE);
assign encod_unlock_dig_process = (state == WAIT_DIG_D) & AD_digested;

assign encod_pre_pre_send_dig_data = (state == START_DIG_D) & (nextstate == WAIT_DIG_D) & AD_digested;

reg pre_send_dig_data, send_dig_data;
always@(posedge clk) begin
    pre_send_dig_data <= encod_pre_pre_send_dig_data;
    send_dig_data <= pre_send_dig_data;
end
assign encod_pre_send_dig_data = pre_send_dig_data;
assign encod_send_dig_data = send_dig_data;


endmodule
