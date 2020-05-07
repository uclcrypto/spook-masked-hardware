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
module shad_core_1R_UMSK
#
(
    // Ns - total number of 2 rounds steps needed ( in units of RA(32SB+2LB) + RB(32SB+DB)).
    parameter Ns = 6,
    // Nbits - Amount of bits per bundle.
    parameter Nbits = 128,
    // BAmount = Bundles amount. Amount of bundle in shadow
    parameter BAmount = 4
)
(
    clk,
    pre_syn_rst,
    // Feeding inputs ///////////////
    // for N
    in_bundle_N, 
    // for B
    in_bundle_B,
    // for data block to digest
    in_bundle_dig_blck,
    // validity flag related to the block to digest
    in_bundle_dig_validity,
    // Controls signals ////////////
    pre_enable,
    feed_init_state,
    dig_decryption,
    dig_not_full,
    dig_first_M,
    // Outputs /////////////////////
    pre_shadow_done,
    release_dig_buffer,
    out_dig_data,
    out_dig_data_validity,
    out_state
);

/////// GENERATION PARAM ///////
// SNbits - Shadow state bits - Amount of bits in shadow state
localparam SNbits = BAmount * Nbits;
// The size of the input block to digest
localparam N2bits = 2*Nbits;
// The size of the input block to digest validity
localparam N2bdiv8 = N2bits/8;
// Nbdiv8 - Nbits/8: the size of the validity signal related to a digested bundle
localparam Nbdiv8 = Nbits/8;

// SLWS divider //
// Serialization of the Round A (extended: Sbox - Lbox - 32 bits constant addition - Sbox): 
// Divide the total amount of 128 bits bundles processed in parallel.
// 4/SLWS_DIVIDER bundles are processed in parallel.
// The Round A is thus performed in SLWS_DIVIDER clock cycles.
// CAUTION: the current architecture only support SLWS_DIVIDER=4.
localparam SLWS_DIVIDER = 4;

// DW divider // 
// Serialization of the Round B (reduced: Dbox - 32 bits constant addition): 
// Divide the total amount of 128 bits bundles processed in parallel.
// 4/DW_DIVIDER bundles are processed in parallel.
// The Round B is thus performed in DW_DIVIDER clock cycles.
// CAUTION: the current architecture only support DW_DIVIDER=4.
localparam DW_DIVIDER = 4;

// Digestion size //
localparam SIZE_DIG_BUS = Nbits;
// Digestion validity size //
localparam SIZE_DIG_V_BUS = SIZE_DIG_BUS/8;

// Step latency
localparam S_LAT = SLWS_DIVIDER + DW_DIVIDER;
// Size of the step cycles counter
parameter SIZE_SCYCLE_CNT = $clog2(S_LAT)+1;
// Size of the step counter 
parameter SIZE_S_CNT = $clog2(Ns)+1;

///// IOs ports //////
input clk;
input pre_syn_rst;
// Feeding inputs ///////////////
// for N
input [Nbits-1:0] in_bundle_N; 
// for B
input [Nbits-1:0] in_bundle_B;
// for data block to digest
input [N2bits-1:0] in_bundle_dig_blck;
// validity flag related to the block to digest
input [N2bdiv8-1:0] in_bundle_dig_validity;
// Controls signals ////////////
input pre_enable;
input feed_init_state;
input dig_decryption;
input dig_not_full;
input dig_first_M;
// Outputs /////////////////////
output pre_shadow_done;
output release_dig_buffer;
output [SIZE_DIG_BUS-1:0] out_dig_data;
output [SIZE_DIG_V_BUS-1:0] out_dig_data_validity;
output [SNbits-1:0] out_state;

// Global enable //
reg glob_enable;
always@(posedge clk)
    glob_enable <= pre_enable | pre_syn_rst;

reg syn_rst;
always@(posedge clk)
    syn_rst <= pre_syn_rst;

// LFSR32 bits
wire rst_W;
wire update_W;
wire [31:0] W32;
lfsr_32
lfsr_unit(
    .clk(clk),
    .n_syn_rst(~rst_W),
    .enable(glob_enable),
    .lfsr_state(W32)
);

// SLWS unit //
wire [SNbits-1:0] bundles_to_SLWS;
wire [SNbits-1:0] bundles_from_SLWS;
SLWS_unit 
slws_core(
    .in_bundles_state(bundles_to_SLWS),
    .in_W32(W32),
    .out_bundles_state_SLWS(bundles_from_SLWS)
);

// DW unit //
wire [SNbits-1:0] bundles_to_DW;
wire [SNbits-1:0] bundles_from_DW;
DW_unit 
dw_core(
    .in_bundles_state(bundles_to_DW),
    .W32(W32),
    .out_bundles_state(bundles_from_DW)
);

// Digestion unit //
wire [SIZE_DIG_BUS-1:0] bundle_state_to_dig;
wire [SIZE_DIG_BUS-1:0] bundle_block_to_dig;
wire [SIZE_DIG_V_BUS-1:0] bundle_block_to_dig_validity;
wire ctrl_en_dig;
wire [SIZE_DIG_BUS-1:0] bundle_state_from_dig;
digestion_unit #(.Nbits(SIZE_DIG_BUS))
dig_core(
    .in_bundle_state(bundle_state_to_dig),
    .in_bundle_block(bundle_block_to_dig),
    .in_bundle_block_validity(bundle_block_to_dig_validity),
    .ctrl_en_digestion(ctrl_en_dig),
    .ctrl_dec_mode(dig_decryption),
    .out_bundle_state(bundle_state_from_dig),
    .out_bundle_block(out_dig_data)
);

// Capacity constant addition //
wire ctrl_en_c_cst_add;
wire [1:0] c_cst = {dig_not_full & ctrl_en_c_cst_add, dig_first_M  & ctrl_en_c_cst_add}; 

wire [Nbits-1:0] bundle_to_c_cst_add;
wire [1:0] bits_c_cst_add = bundle_to_c_cst_add[1:0] ^ c_cst;
wire [Nbits-1:0] bundle_from_c_cst_add = {bundle_to_c_cst_add[Nbits-1:2],bits_c_cst_add};

// Feedback mux //
wire ctrl_fb_from_SDW;
wire [SNbits-1:0] FB_bundles_from_SLWS;
wire [SNbits-1:0] next_bundles_state = ctrl_fb_from_SDW ? bundles_from_DW : FB_bundles_from_SLWS;

// State register //
wire [SNbits-1:0] bundles_state;
dff #(.SIZE(SNbits),.ASYN(0))
state_reg(
    .clk(clk),
    .rst(1'b0),
    .d(next_bundles_state),
    .en(glob_enable),
    .q(bundles_state)
);

///////// Global control ///////////////
// Counter of round cycles //
wire [SIZE_SCYCLE_CNT-1:0] scycles_cnt;
wire rst_scycles_cnt;
wire [SIZE_SCYCLE_CNT-1:0] next_scycles_cnt = scycles_cnt + 1'b1;

dff #(.SIZE(SIZE_SCYCLE_CNT),.ASYN(0))
scycles_cnt_reg(
    .clk(clk),
    .rst(rst_scycles_cnt),
    .d(next_scycles_cnt),
    .en(glob_enable),
    .q(scycles_cnt)
);

// Step counter //
wire [SIZE_S_CNT-1:0] s_cnt;
wire rst_s_cnt;
wire update_s_cnt;
wire [SIZE_S_CNT-1:0] next_s_cnt = update_s_cnt ? s_cnt + 1 : s_cnt;

dff #(.SIZE(SIZE_S_CNT), .ASYN(0))
s_cnt_reg(
    .clk(clk),
    .rst(rst_s_cnt),
    .d(next_s_cnt),
    .en(glob_enable),
    .q(s_cnt)
);

wire last_step = (s_cnt == Ns-1);
wire end_SLW = (scycles_cnt == SLWS_DIVIDER-1);
wire end_SDW = (scycles_cnt == S_LAT-1);
wire pre_shadow_done = end_SDW & last_step;

assign rst_scycles_cnt = end_SDW | syn_rst;
assign rst_s_cnt = pre_shadow_done | syn_rst;
assign update_s_cnt = end_SDW;

assign rst_W = rst_s_cnt;
assign update_W = end_SLW | end_SDW;

assign ctrl_fb_from_SDW = (scycles_cnt >= SLWS_DIVIDER);

//////// PARAMETER DEPENDENT CIRCUITRY /////////
genvar b;

// bundles state (bundles_s) and
// bundles from SLW unit (bundles_fslw)
// as independant bundle
wire [Nbits-1:0] bundles_s [BAmount-1:0];
wire [Nbits-1:0] bundles_fslw [BAmount-1:0];
generate
for(b=0;b<BAmount;b=b+1) begin: state_b_div
    assign bundles_s[b] = bundles_state[Nbits*b +: Nbits];
    assign bundles_fslw[b] = bundles_from_SLWS[Nbits*b +: Nbits];
end
endgenerate

assign out_state = bundles_state;
assign bundles_to_DW = bundles_state;

// Generate construction not required, but kept for future extension  
generate
 if(SLWS_DIVIDER==4) begin
    // RA processed in 4 cycles
    //     128 bits processed in parallel 
    //     128 bits digested in 1 cycle
    //     Initial feed done in 3 cycles
    // The state [S3,S2,S1,S0] is stored as [B3,B2,B1,B0]=[S3,S2,S1,S0];
    
    // Mux for the digestion 
    wire ctrl_dig_b_MSB = ~feed_init_state & (scycles_cnt == 1) & (s_cnt == 0);
    assign bundle_block_to_dig = ctrl_dig_b_MSB ? in_bundle_dig_blck[Nbits +: Nbits] : in_bundle_dig_blck[0 +: Nbits];
    assign bundle_block_to_dig_validity= ctrl_dig_b_MSB ? in_bundle_dig_validity[Nbdiv8 +: Nbdiv8] : in_bundle_dig_validity[0 +: Nbdiv8] ;
    assign bundle_state_to_dig = bundles_s[0]; 
    assign out_dig_data_validity = bundle_block_to_dig_validity;

    // Feeding muxes
    wire ctrl_en_feed0 = feed_init_state & (scycles_cnt == 0) & (s_cnt == 0);
    wire ctrl_en_feed1 = feed_init_state & ((scycles_cnt == 0) | (scycles_cnt == 2)) & (s_cnt == 0);

    wire [Nbits-1:0] mux_feedB2 = ctrl_en_feed0 ? in_bundle_N : bundles_s[2]; 
    wire [Nbits-1:0] mux_feedB1 = ctrl_en_feed1 ? {Nbits{1'b0}} : bundles_s[1];
    wire [Nbits-1:0] mux_feedB0 = ctrl_en_feed0 ? in_bundle_B : bundle_state_from_dig;

    // Capacity constant addition 
    assign bundle_to_c_cst_add = mux_feedB2;
    assign ctrl_en_c_cst_add = ~feed_init_state & (scycles_cnt == 0) & (s_cnt == 0);

    // to SLWS bundle
    assign bundles_to_SLWS = {bundles_s[3], bundle_from_c_cst_add, mux_feedB1, mux_feedB0};
    // SLWS feedback value
    assign FB_bundles_from_SLWS = {bundles_fslw[3],bundles_fslw[2],bundles_fslw[1],bundles_fslw[0]};

    // Release buffer aknowledgment
    assign release_dig_buffer = ~feed_init_state & (scycles_cnt == 1) & (s_cnt == 0);

    // Allow data digestion
    assign ctrl_en_dig = ~feed_init_state & ((scycles_cnt == 0) | (scycles_cnt == 1)) & (s_cnt == 0);
end
endgenerate


endmodule
