/*
    Copyright 2020 UCLouvain

    Licensed under the Solderpad Hardware Licence, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

        https://solderpad.org/licenses/SHL-2.0/

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/
/* 
    Top module of the Spook module
*/
module spook_MSK
#
(
    parameter BUS_SIZE = 32,
    parameter r = 256,
    parameter d = 2,
    parameter PDSBOX=2,
    parameter PDLBOX=1,
    parameter n = 128
)
(
    clk,
    rst,
    // Instruction bus in
    bus_in,
    bus_in_valid,
    ready_bus_in,
    // Status out
    bus_out,
    bus_out_valid,
    ready_bus_out,
    bus_out_last
);
// Generation param
localparam BUSdiv8 = BUS_SIZE /8;
localparam rd8 = r/8;
localparam nd8 = n/8;

// IOs 
input clk;
input rst;
// Instruction bus in
input [BUS_SIZE-1:0] bus_in;
input bus_in_valid;
output ready_bus_in;
// Status out
output [BUS_SIZE-1:0] bus_out;
output bus_out_valid;
input ready_bus_out;
output bus_out_last;

// Inter modules wires ///////////////////////
// Controller <-> Decoder
wire from_cntrl_rdy_instr_fetch;
wire from_cntrl_rdy_head_fetch;
wire from_cntrl_rdy_data_fetch;

wire to_cntrl_instruction_valid;
wire to_cntrl_decrypt;
wire to_cntrl_key_update;
wire to_cntrl_key_only;
wire to_cntrl_seed_update;

wire to_cntrl_header_valid;
wire [3:0] to_cntrl_dtype;
wire to_cntrl_eot;
wire to_cntrl_eoi;
wire [15:0]  to_cntrl_length;
wire to_cntrl_seg_empty;
wire [3:0] to_cntrl_sel_nibble;

wire to_cntrl_data_out_valid;
wire to_cntrl_data_out_partial;
wire to_cntrl_data_out_last_of_seg;

// Datapath <-> Decoder
wire [BUS_SIZE-1:0] to_dp_data_out;
wire [BUSdiv8-1:0]  to_dp_data_out_validity;

// Controller <-> Datapath

wire to_dp_ctrl_mux_tag_computation;
wire to_dp_initialisation;
wire to_dp_ctrl_en_tag_verif;
wire from_dp_tag_is_valid; 

wire to_dp_bb_flag_cnst_add_done;
wire to_dp_bb_en_update;
wire to_dp_bb_en_padding;

wire to_dp_keyh_enable_feeding;
wire to_dp_keyh_rst;
wire to_dp_keyh_n_lock_for_seed;
wire to_dp_keyh_feed_prng; 
wire from_dp_keyh_rdy_refresh;
wire to_dp_keyh_start_refresh;

wire to_dp_NTh_enable_feeding;

wire to_dp_shad_pre_rst;
wire to_dp_shad_pre_enable;
wire to_dp_shad_dig_decryption;
wire to_dp_shad_dig_not_full;
wire to_dp_shad_dig_first_M;
wire from_dp_shad_pre_done;
wire from_dp_shad_release_dig;

wire to_dp_clyde_inverse;
wire to_dp_clyde_pre_data_in_valid;
wire from_dp_clyde_pre_data_out_valid;
wire to_dp_clyde_pre_enable;
wire to_dp_clyde_en_feeding_prng1;
wire to_dp_clyde_en_feeding_prng2;
wire to_dp_clyde_lock_feed1;
wire to_dp_clyde_lock_feed2;
wire from_dp_clyde_ready_start;

// Controller <-> Encoder
wire to_encod_status_sel;
wire to_encod_pre_send_header;
wire to_encod_send_header;
wire to_encod_pre_send_status;
wire to_encod_send_status;
wire to_encod_pre_send_tag;
wire to_encod_send_tag;

wire to_encod_unlock_dig_process;
wire to_encod_pre_pre_send_dig_data;
wire to_encod_pre_send_dig_data;
wire to_encod_send_dig_data;

wire [3:0] to_encod_dtype;
wire to_encod_eot;
wire to_encod_eoi;
wire to_encod_last;
wire [15:0] to_encod_length;

wire from_encod_ready;
wire from_encod_pre_ready;
wire from_encod_release_buffer;

// Datapath <-> Encoder
wire [n-1:0] to_enc_bundle_blck_out;
wire [nd8-1:0] to_enc_bundle_blck_out_validity;
wire [n-1:0] to_enc_tag;

// Decoder module ///////////////////////////

decoder  #(.BUS_SIZE(32))
dec_core  ( 
    .clk(clk),
    .rst(rst),
    // Instruction bus in
    .data_in(bus_in),
    .data_in_valid(bus_in_valid),
    .ready(ready_bus_in),
    // Controller <-> Decoder
    .from_cntrl_rdy_instr_fetch(from_cntrl_rdy_instr_fetch),
    .from_cntrl_rdy_head_fetch(from_cntrl_rdy_head_fetch),
    .from_cntrl_rdy_data_fetch(from_cntrl_rdy_data_fetch),
    .to_cntrl_instruction_valid(to_cntrl_instruction_valid),
    .to_cntrl_decrypt(to_cntrl_decrypt),
    .to_cntrl_key_update(to_cntrl_key_update),
    .to_cntrl_key_only(to_cntrl_key_only),
    .to_cntrl_seed_update(to_cntrl_seed_update),
    .to_cntrl_header_valid(to_cntrl_header_valid),
    .to_cntrl_dtype(to_cntrl_dtype),
    .to_cntrl_eot(to_cntrl_eot),
    .to_cntrl_eoi(to_cntrl_eoi),
    .to_cntrl_length(to_cntrl_length),
    .to_cntrl_seg_empty(to_cntrl_seg_empty),
    .to_cntrl_sel_nibble(to_cntrl_sel_nibble),
    .to_cntrl_data_out_valid(to_cntrl_data_out_valid),
    .to_cntrl_data_out_partial(to_cntrl_data_out_partial),
    .to_cntrl_data_out_last_of_seg(to_cntrl_data_out_last_of_seg),
    // Datapath <-> Decoder
    .to_dp_data_out(to_dp_data_out),
    .to_dp_data_out_validity(to_dp_data_out_validity)
);

// Controller module /////////////////////
controller #(.BUS_SIZE(BUS_SIZE),.r(r))
cntrl_core ( 
    .clk(clk),
    .rst(rst),
    // Controller <-> Decoder
    .from_decod_instruction_valid(to_cntrl_instruction_valid),
    .from_decod_header_valid(to_cntrl_header_valid),
    .from_decod_data_in_valid(to_cntrl_data_out_valid),
    .to_decod_rdy_instr_fetch(from_cntrl_rdy_instr_fetch),
    .to_decod_rdy_head_fetch(from_cntrl_rdy_head_fetch),
    .to_decod_rdy_data_fetch(from_cntrl_rdy_data_fetch),
    .from_decod_decrypt(to_cntrl_decrypt),
    .from_decod_key_update(to_cntrl_key_update),
    .from_decod_key_only(to_cntrl_key_only),
    .from_decod_seed_update(to_cntrl_seed_update),
    .from_decod_dtype(to_cntrl_dtype),
    .from_decod_eot(to_cntrl_eot),
    .from_decod_eoi(to_cntrl_eoi),
    .from_decod_length(to_cntrl_length),
    .from_decod_seg_empty(to_cntrl_seg_empty),
    .from_decod_sel_nibble(to_cntrl_sel_nibble),
    .from_decod_data_in_partial(to_cntrl_data_out_partial),
    .from_decod_data_in_last_of_seg(to_cntrl_data_out_last_of_seg),
    // Controller <-> Datapath
    .to_dp_bb_flag_cnst_add_done(to_dp_bb_flag_cnst_add_done),
    .to_dp_bb_en_update(to_dp_bb_en_update),
    .to_dp_bb_en_padding(to_dp_bb_en_padding),
    .to_dp_ctrl_mux_tag_computation(to_dp_ctrl_mux_tag_computation),
    .to_dp_initialisation(to_dp_initialisation),
    .to_dp_ctrl_en_tag_verif(to_dp_ctrl_en_tag_verif),
    .from_dp_tag_is_valid(from_dp_tag_is_valid),
    .to_dp_keyh_enable_feeding(to_dp_keyh_enable_feeding),
    .to_dp_keyh_rst(to_dp_keyh_rst),
    .to_dp_keyh_n_lock_for_seed(to_dp_keyh_n_lock_for_seed),
    .to_dp_keyh_feed_prng(to_dp_keyh_feed_prng),
    .from_dp_keyh_rdy_refresh(from_dp_keyh_rdy_refresh),
    .to_dp_keyh_start_refresh(to_dp_keyh_start_refresh),
    .to_dp_NTh_enable_feeding(to_dp_NTh_enable_feeding),
    .to_dp_shad_pre_rst(to_dp_shad_pre_rst),
    .to_dp_shad_pre_enable(to_dp_shad_pre_enable),
    .to_dp_shad_dig_decryption(to_dp_shad_dig_decryption),
    .to_dp_shad_dig_not_full(to_dp_shad_dig_not_full),
    .to_dp_shad_dig_first_M(to_dp_shad_dig_first_M),
    .from_dp_shad_pre_done(from_dp_shad_pre_done),
    .from_dp_shad_release_dig(from_dp_shad_release_dig),
    .to_dp_clyde_inverse(to_dp_clyde_inverse),
    .to_dp_clyde_pre_data_in_valid(to_dp_clyde_pre_data_in_valid),
    .from_dp_clyde_pre_data_out_valid(from_dp_clyde_pre_data_out_valid),
    .to_dp_clyde_pre_enable(to_dp_clyde_pre_enable),
    .to_dp_clyde_en_feeding_prng1(to_dp_clyde_en_feeding_prng1),
    .to_dp_clyde_en_feeding_prng2(to_dp_clyde_en_feeding_prng2),
    .to_dp_clyde_lock_feed1(to_dp_clyde_lock_feed1),
    .to_dp_clyde_lock_feed2(to_dp_clyde_lock_feed2),
    .from_dp_clyde_ready_start(from_dp_clyde_ready_start),

    // Controller <-> Encoder
    .to_encod_dtype(to_encod_dtype),
    .to_encod_eot(to_encod_eot),
    .to_encod_eoi(to_encod_eoi),
    .to_encod_last(to_encod_last),
    .to_encod_length(to_encod_length),

    .to_encod_status_sel(to_encod_status_sel),
    .to_encod_pre_send_header(to_encod_pre_send_header),
    .to_encod_send_header(to_encod_send_header),
    .to_encod_pre_send_status(to_encod_pre_send_status),
    .to_encod_send_status(to_encod_send_status),
    .to_encod_pre_send_tag(to_encod_pre_send_tag),
    .to_encod_send_tag(to_encod_send_tag),
    .to_encod_unlock_dig_process(to_encod_unlock_dig_process),
    .to_encod_pre_pre_send_dig_data(to_encod_pre_pre_send_dig_data),
    .to_encod_pre_send_dig_data(to_encod_pre_send_dig_data),
    .to_encod_send_dig_data(to_encod_send_dig_data),
    .from_encod_pre_ready(from_encod_pre_ready),
    .from_encod_ready(from_encod_ready),
    .from_encod_release_buffer(from_encod_release_buffer)
);

// Datapath module ////////////////////
datapath #(
    .BUS_SIZE(BUS_SIZE),
    .r(r),
    .d(d),
    .PDSBOX(PDSBOX),
    .PDLBOX(PDLBOX)
) 
datapath_core ( 
    // General
    .clk(clk),
    .rst(rst),
    .ctrl_mux_tag_computation(to_dp_ctrl_mux_tag_computation),
    .initialisation(to_dp_initialisation),
    .ctrl_en_tag_verif(to_dp_ctrl_en_tag_verif),
    .tag_is_valid(from_dp_tag_is_valid),
    // From decoder
    .from_decod_data_in(to_dp_data_out),
    .from_decod_data_in_validity(to_dp_data_out_validity),
    // Block builder //////////
    .from_cntrl_bb_flag_cnst_add_done(to_dp_bb_flag_cnst_add_done),
    .from_cntrl_bb_en_update(to_dp_bb_en_update),
    .from_cntrl_bb_en_padding(to_dp_bb_en_padding),
    // Key_holder
    .keyh_enable_feeding(to_dp_keyh_enable_feeding),
    .keyh_rst(to_dp_keyh_rst),
    .keyh_n_lock_for_seed(to_dp_keyh_n_lock_for_seed),
    .keyh_feed_prng(to_dp_keyh_feed_prng),
    .keyh_rdy_refresh(from_dp_keyh_rdy_refresh),
    .keyh_start_refresh(to_dp_keyh_start_refresh),
    // Nonce/TAG holder // 
    .NTh_enable_feeding(to_dp_NTh_enable_feeding),
    // Shadow //
    .shad_pre_rst(to_dp_shad_pre_rst),
    .shad_pre_enable(to_dp_shad_pre_enable),
    .shad_dig_decryption(to_dp_shad_dig_decryption),
    .shad_dig_not_full(to_dp_shad_dig_not_full),
    .shad_dig_first_M(to_dp_shad_dig_first_M),
    .shad_pre_done(from_dp_shad_pre_done),
    .shad_release_dig(from_dp_shad_release_dig),
    // Clyde //
    .clyde_inverse(to_dp_clyde_inverse),
    .clyde_pre_data_in_valid(to_dp_clyde_pre_data_in_valid),
    .clyde_pre_data_out_valid(from_dp_clyde_pre_data_out_valid),
    .clyde_pre_enable(to_dp_clyde_pre_enable),
    .clyde_en_feeding_prng1(to_dp_clyde_en_feeding_prng1),
    .clyde_en_feeding_prng2(to_dp_clyde_en_feeding_prng2),
    .clyde_lock_feed1(to_dp_clyde_lock_feed1),
    .clyde_lock_feed2(to_dp_clyde_lock_feed2),
    .clyde_ready_start(from_dp_clyde_ready_start),
    // Encoder //////////////
    .to_enc_bundle_blck_out(to_enc_bundle_blck_out),
    .to_enc_bundle_blck_out_validity(to_enc_bundle_blck_out_validity),
    .to_enc_tag(to_enc_tag)
);

// Encoder module ///////////////////////
encoder 
encoder_core ( 
    .clk(clk),
    .syn_rst(rst),
    // Status bus out
    .data_out(bus_out),
    .data_out_valid(bus_out_valid),
    .ready_ext(ready_bus_out),
    // Datapath <-> Encoder
    .dig_bundle_data(to_enc_bundle_blck_out),
    .dig_bundle_data_validity(to_enc_bundle_blck_out_validity),
    .tag_computed(to_enc_tag),
    // Controller <-> Encoder
    .head_dtype(to_encod_dtype),
    .head_eot(to_encod_eot),
    .head_eoi(to_encod_eoi),
    .head_last(to_encod_last),
    .head_length(to_encod_length),
    .status_sel(to_encod_status_sel),
    .pre_send_header(to_encod_pre_send_header),
    .send_header(to_encod_send_header),
    .pre_send_status(to_encod_pre_send_status),
    .send_status(to_encod_send_status),
    .pre_send_tag(to_encod_pre_send_tag),
    .send_tag(to_encod_send_tag),
    .unlock_dig_process(to_encod_unlock_dig_process),
    .pre_pre_send_dig_data(to_encod_pre_pre_send_dig_data),
    .pre_send_dig_data(to_encod_pre_send_dig_data),
    .send_dig_data(to_encod_send_dig_data),
    // Core status signal to controller //
    .pre_ready(from_encod_pre_ready),
    .ready(from_encod_ready),
    .release_buffer(from_encod_release_buffer),
    .data_out_last(bus_out_last)
);

endmodule
