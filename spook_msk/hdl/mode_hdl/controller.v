/*
    Top module of the global controller. 
*/
module controller
#
(
    parameter BUS_SIZE = 32,
    parameter r = 256
)
(
    clk,
    rst,
    // Decoder ////////////////////
    from_decod_instruction_valid,
    from_decod_header_valid,
    from_decod_data_in_valid,

    to_decod_rdy_instr_fetch,
    to_decod_rdy_head_fetch,
    to_decod_rdy_data_fetch,
    // instruction related
    from_decod_decrypt,
    from_decod_key_update,
    from_decod_key_only,
    from_decod_seed_update,
    // header related
    from_decod_dtype,
    from_decod_eot,
    from_decod_eoi,
    from_decod_length,
    from_decod_seg_empty,
    from_decod_sel_nibble,
    // data related 
    from_decod_data_in_partial,
    from_decod_data_in_last_of_seg,
    // Datapath /////////////////////////
    to_dp_ctrl_mux_tag_computation,
    to_dp_initialisation,
    to_dp_ctrl_en_tag_verif,
    from_dp_tag_is_valid,

    to_dp_bb_flag_cnst_add_done,
    to_dp_bb_en_update,
    to_dp_bb_en_padding,

    to_dp_keyh_enable_feeding,
    to_dp_keyh_rst,
    to_dp_keyh_n_lock_for_seed,
    to_dp_keyh_feed_prng,
    from_dp_keyh_rdy_refresh,
    to_dp_keyh_start_refresh,

    to_dp_NTh_enable_feeding,

    to_dp_shad_pre_rst,
    to_dp_shad_pre_enable,
    to_dp_shad_dig_decryption,
    to_dp_shad_dig_not_full,
    to_dp_shad_dig_first_M,
    from_dp_shad_pre_done,
    from_dp_shad_release_dig,

    to_dp_clyde_inverse,
    to_dp_clyde_pre_data_in_valid,
    from_dp_clyde_pre_data_out_valid,
    to_dp_clyde_pre_enable,
    to_dp_clyde_en_feeding_prng1,
    to_dp_clyde_en_feeding_prng2,
    to_dp_clyde_lock_feed1,
    to_dp_clyde_lock_feed2,
    from_dp_clyde_ready_start,

    // Encoder ///////////////
    to_encod_dtype,
    to_encod_eot,
    to_encod_eoi,
    to_encod_last,
    to_encod_length,

    to_encod_status_sel,
    to_encod_pre_send_header,
    to_encod_send_header,
    to_encod_pre_send_status,
    to_encod_send_status,
    to_encod_pre_send_tag,
    to_encod_send_tag,
    to_encod_unlock_dig_process,
    to_encod_pre_pre_send_dig_data,
    to_encod_pre_send_dig_data,
    to_encod_send_dig_data,

    from_encod_pre_ready,
    from_encod_ready,
    from_encod_release_buffer
);

// Generation params 
localparam BUSdiv8 = BUS_SIZE/8;

// IOs ports 
input clk;
input rst;
input from_decod_instruction_valid;
input from_decod_header_valid;
input from_decod_data_in_valid; 

output to_decod_rdy_instr_fetch;
output to_decod_rdy_head_fetch;
output to_decod_rdy_data_fetch;

input from_decod_decrypt;
input from_decod_key_update;
input from_decod_key_only;
input from_decod_seed_update;

input [3:0] from_decod_dtype;
input from_decod_eot;
input from_decod_eoi;
input [15:0] from_decod_length;
input from_decod_seg_empty;
input [3:0] from_decod_sel_nibble;

input from_decod_data_in_partial;
input from_decod_data_in_last_of_seg;

output to_dp_ctrl_mux_tag_computation;
output to_dp_initialisation;
output to_dp_ctrl_en_tag_verif;
input from_dp_tag_is_valid; 

output to_dp_bb_flag_cnst_add_done;
output to_dp_bb_en_update;
output to_dp_bb_en_padding;

output to_dp_keyh_enable_feeding;
output to_dp_keyh_rst;
output to_dp_keyh_n_lock_for_seed;
output to_dp_keyh_feed_prng; 
input from_dp_keyh_rdy_refresh;
output to_dp_keyh_start_refresh;

output to_dp_NTh_enable_feeding;

output to_dp_shad_pre_rst;
output to_dp_shad_pre_enable;
output to_dp_shad_dig_decryption;
output to_dp_shad_dig_not_full;
output to_dp_shad_dig_first_M;
input from_dp_shad_pre_done;
input from_dp_shad_release_dig;

output to_dp_clyde_inverse;
output to_dp_clyde_pre_data_in_valid;
input from_dp_clyde_pre_data_out_valid;
output to_dp_clyde_pre_enable;
output to_dp_clyde_en_feeding_prng1;
output to_dp_clyde_en_feeding_prng2;
output to_dp_clyde_lock_feed1;
output to_dp_clyde_lock_feed2;
input from_dp_clyde_ready_start;

output [3:0] to_encod_dtype;
output to_encod_eot;
output to_encod_eoi;
output to_encod_last;
output [15:0] to_encod_length;

output to_encod_status_sel;
output to_encod_pre_send_header;
output to_encod_send_header;
output to_encod_pre_send_status;
output to_encod_send_status;
output to_encod_pre_send_tag;
output to_encod_send_tag;
output to_encod_unlock_dig_process;
output to_encod_pre_pre_send_dig_data;
output to_encod_pre_send_dig_data;
output to_encod_send_dig_data;

input from_encod_pre_ready;
input from_encod_ready;
input from_encod_release_buffer;

// Inter sub_controllers signals /////////////////////
// Block builder
wire dig_blck_ready, blck_bld_set_ready, blck_bld_ready;
wire blck_bld_data_in_eot;

// Encoder 
wire to_enc_out_tag_selected;

// Spook mode controller //
spook_cntrl 
spook_core( 
    .clk(clk),
    .rst(rst),
    // Decoder ////////////
    .instruction_valid(from_decod_instruction_valid),
    .header_valid(from_decod_header_valid),
    .data_in_valid(from_decod_data_in_valid),
    .rdy_instr_fetch(to_decod_rdy_instr_fetch),
    .rdy_head_fetch(to_decod_rdy_head_fetch),
    .rdy_data_fetch(to_decod_rdy_data_fetch),
    .decrypt(from_decod_decrypt),
    .key_update(from_decod_key_update),
    .key_only(from_decod_key_only),
    .seed_update(from_decod_seed_update),
    .dec_seg_empty(from_decod_seg_empty),
    .dec_dtype(from_decod_dtype),
    .dec_eot(from_decod_eot),
    .dec_eoi(from_decod_eoi),
    .dec_length(from_decod_length),
    .dec_sel_nibble(from_decod_sel_nibble),
    .data_in_last_of_seg(from_decod_data_in_last_of_seg),

    // Datapath ////////////
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

    // Other controllers ///////////
    // Blck_builder
    .dig_blck_ready(dig_blck_ready),
    .blck_bld_data_in_eot(blck_bld_data_in_eot),
    .ready_ext_blck_builder(blck_bld_ready),
    .blck_bld_set_ready(blck_bld_set_ready),

    // Encoder
    .encod_dtype(to_encod_dtype),
    .encod_eot(to_encod_eot),
    .encod_eoi(to_encod_eoi),
    .encod_last(to_encod_last),
    .encod_length(to_encod_length),

    .encod_status_sel(to_encod_status_sel),
    .encod_pre_send_header(to_encod_pre_send_header),
    .encod_send_header(to_encod_send_header),
    .encod_pre_send_status(to_encod_pre_send_status),
    .encod_send_status(to_encod_send_status),
    .encod_pre_send_tag(to_encod_pre_send_tag),
    .encod_send_tag(to_encod_send_tag),
    .encod_unlock_dig_process(to_encod_unlock_dig_process),
    .encod_pre_ready(from_encod_pre_ready),
    .encod_ready(from_encod_ready),
    .encod_release_buffer(from_encod_release_buffer),
    .encod_pre_pre_send_dig_data(to_encod_pre_pre_send_dig_data),
    .encod_pre_send_dig_data(to_encod_pre_send_dig_data),
    .encod_send_dig_data(to_encod_send_dig_data)
);

// Block builder controller
blck_builder_cntrl #(.BUS_SIZE(BUS_SIZE),.BLCK_SIZE(r))
blkc_build_core ( .clk(clk),
    .rst(rst),
    // Decoder //////////////////
    .data_in_valid(from_decod_data_in_valid),
    .data_in_partial(from_decod_data_in_partial),
    .data_in_eot(blck_bld_data_in_eot),
    // Datapath ////////////////
    .flag_cnst_add_done(to_dp_bb_flag_cnst_add_done),
    .en_update(to_dp_bb_en_update),
    .en_padding(to_dp_bb_en_padding),
    // Other controllers //////////
    .set_ready(blck_bld_set_ready),
    .ready(blck_bld_ready),
    .blck_out_rdy(dig_blck_ready)
);

assign to_dp_shad_dig_not_full = to_dp_bb_flag_cnst_add_done;

endmodule
