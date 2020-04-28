/*
    Top module of the global datapath.
*/
module datapath
#
(
    parameter BUS_SIZE = 32,
    parameter r = 256,
    parameter t = 128,
    parameter n = 128,
    parameter d = 2,
    parameter PDSBOX = 2,
    parameter PDLBOX = 1,
    parameter SIZE_RND_GEN_KEY=16    
)
(
    // General
    clk,
    rst,
    ctrl_mux_tag_computation,
    initialisation,
    ctrl_en_tag_verif,
    tag_is_valid,
    // From decoder
    from_decod_data_in,
    from_decod_data_in_validity,
    // Block builder //////////
    from_cntrl_bb_flag_cnst_add_done,
    from_cntrl_bb_en_update,
    from_cntrl_bb_en_padding,
    // Key_holder
    keyh_enable_feeding,
    keyh_rst,
    keyh_n_lock_for_seed,
    keyh_feed_prng,
    keyh_rdy_refresh,
    keyh_start_refresh,
    // Nonce/TAG holder // 
    NTh_enable_feeding,
    // Shadow //
    shad_pre_rst,
    shad_pre_enable,
    shad_dig_decryption,
    shad_dig_not_full,
    shad_dig_first_M,
    shad_pre_done,
    shad_release_dig,
    // Clyde //
    clyde_inverse,
    clyde_pre_data_in_valid,
    clyde_pre_data_out_valid,
    clyde_pre_enable,
    clyde_en_feeding_prng1,
    clyde_en_feeding_prng2,
    clyde_ready_start,
    // Encoder //////////////
    to_enc_bundle_blck_out,
    to_enc_bundle_blck_out_validity,
    to_enc_tag
);

// Generation parameters
localparam BUSdiv8 = BUS_SIZE/8;
localparam rd8 = r/8;
localparam nd8 = n/8;

localparam SIZE_SHARING = d*n;

localparam SIZE_SHAD = 4*n;
localparam SIZE_DIG_BUS = n;
localparam SIZE_DIG_V_BUS = SIZE_DIG_BUS/8;

// General
input clk;
input rst;
input ctrl_mux_tag_computation;
input initialisation;
input ctrl_en_tag_verif;
output tag_is_valid;
// From decoder
input [BUS_SIZE-1:0] from_decod_data_in;
input [BUSdiv8-1:0] from_decod_data_in_validity;
// Block builder //////////
input from_cntrl_bb_flag_cnst_add_done;
input from_cntrl_bb_en_update;
input from_cntrl_bb_en_padding;
// Key_holder
input keyh_enable_feeding;
input keyh_rst;
input keyh_feed_prng; 
input keyh_n_lock_for_seed;
output keyh_rdy_refresh;
input keyh_start_refresh;
// Nonce/TAG holder // 
input NTh_enable_feeding;
// Shadow //
input shad_pre_rst;
input shad_pre_enable;
input shad_dig_decryption;
input shad_dig_not_full;
input shad_dig_first_M;
output shad_pre_done;
output shad_release_dig;
// Clyde //
input clyde_inverse;
input clyde_pre_data_in_valid;
output clyde_pre_data_out_valid;
input clyde_pre_enable;
input clyde_en_feeding_prng1;
input clyde_en_feeding_prng2;
output clyde_ready_start;
// Encoder //////////////
output [n-1:0] to_enc_bundle_blck_out;
output [nd8-1:0] to_enc_bundle_blck_out_validity;
output [n-1:0] to_enc_tag;


//////// Key holder/refresher core ////////
wire [SIZE_SHARING-1:0] sharing_key;
MSKkey_holder_rfrsh #(.d(d),.Nbits(n),.SIZE_FEED(BUS_SIZE),.SIZE_RND_GEN(SIZE_RND_GEN_KEY))
key_holder(
    .clk(clk),
    .pre_rst(keyh_rst),
    .data_in(from_decod_data_in),
    .data_in_valid(keyh_enable_feeding),
    .sharing_key_out(sharing_key),
    .n_lock_for_seed(keyh_n_lock_for_seed),
    .feed_prng_seed(keyh_feed_prng),
    .rnd_ready(keyh_rdy_refresh),
    .pre_pre_refresh(keyh_start_refresh)
);

/////// Nonce/TAG holder logic /////         
reg [n-1:0] NTh; 
wire update_NTh = NTh_enable_feeding;
wire [n-1:0] next_NTh = update_NTh ? {from_decod_data_in, NTh[BUS_SIZE +: n-BUS_SIZE]} : NTh;
always@(posedge clk)
    NTh <= next_NTh;

//////// Block builder datapath //////
wire [r-1:0] bb_blck_out;
wire [rd8-1:0] bb_blck_out_validity;
blck_builder_dp  #(.BUS_SIZE(BUS_SIZE),.BLCK_SIZE(r))
bb_dp_core (.clk(clk),
    .rst(rst),
    // Decoder 
    .data_in(from_decod_data_in),
    .data_in_validity(from_decod_data_in_validity),
    // Controller
    .flag_cnst_add_done(from_cntrl_bb_flag_cnst_add_done),
    .en_update(from_cntrl_bb_en_update),
    .en_padding(from_cntrl_bb_en_padding),
    // Other datapaths core
    .blck_out(bb_blck_out),
    .blck_out_validity(bb_blck_out_validity)
);

/////// Shadow core /////////
wire [n-1:0] shad_B;
wire [SIZE_SHAD-1:0] shad_out_state; 
shad_core_1R_UMSK 
shad_core(
    .clk(clk),
    .pre_syn_rst(rst | shad_pre_rst),
    .in_bundle_N(NTh),
    .in_bundle_B(shad_B),
    .in_bundle_dig_blck(bb_blck_out),
    .in_bundle_dig_validity(bb_blck_out_validity),
    .pre_enable(shad_pre_enable),
    .feed_init_state(initialisation),
    .dig_decryption(shad_dig_decryption),
    .dig_not_full(shad_dig_not_full),
    .dig_first_M(shad_dig_first_M),
    .pre_shadow_done(shad_pre_done),
    .release_dig_buffer(shad_release_dig),
    .out_dig_data(to_enc_bundle_blck_out),
    .out_dig_data_validity(to_enc_bundle_blck_out_validity),
    .out_state(shad_out_state)
);

/////// Clyde core ////////////
wire [n-1:0] clyde_data_in;
wire [n-1:0] clyde_tweak;
wire [n-1:0] clyde_data_out;
MSKclyde_128 #(.d(d),.PDSBOX(PDSBOX),.PDLBOX(PDLBOX),.SIZE_FEED(BUS_SIZE))
clyde_core(
    .clk(clk),
    .pre_syn_rst(rst),
    .inverse(clyde_inverse),
    .data_in(clyde_data_in),
    .pre_data_in_valid(clyde_pre_data_in_valid),
    .sharing_key(sharing_key),
    .tweak(clyde_tweak),
    .data_out(clyde_data_out),
    .pre_data_out_valid(clyde_pre_data_out_valid),
    .pre_enable(clyde_pre_enable),
    .feed1(clyde_en_feeding_prng1),
    .feed_data(from_decod_data_in),
    .feed2(clyde_en_feeding_prng2),
    .ready_start_run(clyde_ready_start)
);

// Mode routing //
// Clyde input is either the N/T or the first 128 bits of shadow when the tag is computed
assign clyde_data_in = ctrl_mux_tag_computation ? shad_out_state[0 +: n] : NTh;
assign clyde_tweak = initialisation ? {n{1'b0}} : {1'b1,shad_out_state[n +: n-1]};

assign shad_B = clyde_data_out;

// Logic to check the tag comparison 
wire [n-1:0] inverse_tag = ctrl_en_tag_verif ? clyde_data_out : {n{1'b0}};
wire tag_is_valid = (shad_out_state[0 +: n] == inverse_tag);

assign to_enc_tag = clyde_data_out;

endmodule



