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
    This module is used to generate the outputs of the 
    module following the communication protocole chosen. 
*/
module encoder_dp
#
(
    parameter BUS_SIZE = 32,
    parameter n = 128,
    parameter BLCK_SIZE = 256
)
(
    clk,
    // Data to process //
    // Header data
    head_dtype,
    head_eot,
    head_eoi,
    head_last,
    head_length,
    // Status choice
    status_sel,
    // From datapath
    dig_bundle_data,
    dig_bundle_data_validity,
    tag_computed,
    // To external bus
    data_out_valid,
    data_out,
    // Controls ///////////////
    ctrl_mux_sel_status, //(1: status, 0: header)
    ctrl_mux_sel_seginfo, //(1: seginfo, 0: tag)
    ctrl_mux_sel_bypass_bundle, //(1: bypass bundle, 0: tag or seginfo)
    enable_4H,
    enable_4L,
    unlock_validity,
    mux_out_ctrl,
    early_invalid
);

// Generation params 
localparam BUSdiv8 = BUS_SIZE/8;
localparam nd8 = n/8;
localparam BLCKdiv8 = BLCK_SIZE/8;
localparam ndivBUS = n / BUS_SIZE;
localparam BLCKdivBUS = BLCK_SIZE / BUS_SIZE;

// IOs ports 
input clk;
input [3:0] head_dtype;
input head_eot;
input head_eoi;
input head_last;
input [15:0] head_length;
input status_sel;
input [n-1:0] dig_bundle_data;
input [nd8-1:0] dig_bundle_data_validity;
input [n-1:0] tag_computed;
output data_out_valid;
output [BUS_SIZE-1:0] data_out;
input ctrl_mux_sel_status; //(1: status, 0: header;
input ctrl_mux_sel_seginfo; //(1: seginfo, 0: tag)
input ctrl_mux_sel_bypass_bundle; //(1: bypass bundle, 0: tag or seginfo)
input enable_4H;
input enable_4L;
input unlock_validity;
input [2:0] mux_out_ctrl;
output early_invalid;


// Data holder logic ////////////////////////
// Bus size long dff (output data buffer) //
genvar i;
generate
for(i=0;i<BLCKdivBUS;i=i+1) begin: dh
    wire [BUS_SIZE-1:0] d,q;
    wire enable_dff;

    if(i<ndivBUS) begin
        assign enable_dff = enable_4L;
    end else begin
        assign enable_dff = enable_4H;
    end

    dff #(.SIZE(BUS_SIZE),.ASYN(0))
    dh_rg(
        .clk(clk),
        .rst(1'b0),
        .d(d),
        .en(enable_dff),
        .q(q)
    );
end
endgenerate

// Header encoder unit //
wire [BUS_SIZE-1:0] header_encoded;
header_encoder 
head_enc_unit(
    .dtype(head_dtype),
    .eot(head_eot),
    .eoi(head_eoi),
    .last(head_last),
    .length(head_length),
    .header(header_encoded)
);

// Status encoder //
wire [BUS_SIZE-1:0] status_encoded;
status_encoder 
status_enc_unit(
    .status_sel(status_sel),
    .status(status_encoded)
);

// Feeding registers //
// L2 mux: header or status chosen 
wire [BUS_SIZE-1:0] mux_head_status = ctrl_mux_sel_status ? status_encoded : header_encoded;

// L1 mux: seginfo or tag chosen 
wire [BUS_SIZE-1:0] mux_seginfo_tag = ctrl_mux_sel_seginfo ? mux_head_status : tag_computed[0 +: BUS_SIZE];

// L0 mux: tag or bundle 
wire [BUS_SIZE-1:0] mux_bundle_tag [ndivBUS-1:0];
generate
for(i=0;i<ndivBUS;i=i+1) begin: muxL0
    if(i==0) begin
        assign mux_bundle_tag[i] = ctrl_mux_sel_bypass_bundle ? dh[i+ndivBUS].q : mux_seginfo_tag;
    end else begin
        assign mux_bundle_tag[i] = ctrl_mux_sel_bypass_bundle ? dh[i+ndivBUS].q : tag_computed[i*BUS_SIZE +: BUS_SIZE];
    end
end
endgenerate

// dh data feeding 
generate
for(i=0;i<BLCKdivBUS;i=i+1) begin: d_assig_dh
    if(i<ndivBUS) begin
        assign dh[i].d = mux_bundle_tag[i];
    end else begin
        assign dh[i].d = dig_bundle_data[(i-ndivBUS)*BUS_SIZE +: BUS_SIZE];
    end
end
endgenerate

// Data holder logic //////////////////////////////
// validity holder dffs //
generate 
for(i=0;i<BLCKdivBUS;i=i+1) begin:vh
    wire [BUSdiv8-1:0] d, q;
    wire enable_dff;

    if(i<ndivBUS) begin
        assign enable_dff = enable_4L;
    end else begin
        assign enable_dff = enable_4H;
    end

    dff #(.SIZE(BUSdiv8),.ASYN(0))
    vh_rg(
        .clk(clk),
        .rst(1'b0),
        .d(d),
        .en(enable_dff),
        .q(q)
    );
end
endgenerate

// L1 mux: choice between 0 (for seginfo) or 1* (for tag) 
wire [BUSdiv8-1:0] mux_v_L1_seginfo = ctrl_mux_sel_seginfo ? {BUSdiv8{1'b0}} : {BUSdiv8{1'b1}}; 

// L0 muxes: choice between bypass bundle validity or constant(in case of tag or seginfo)
wire [BUSdiv8-1:0] mux_v_bypass_bundle [ndivBUS:0];
generate
for(i=0;i<ndivBUS;i=i+1) begin:mux_v_bp_bundle
    if(i<ndivBUS) begin
        if(i!=1) begin
            assign mux_v_bypass_bundle[i] = ctrl_mux_sel_bypass_bundle ? vh[i+ndivBUS].q : {BUSdiv8{1'b1}}; 
        end else begin
            assign mux_v_bypass_bundle[i] = ctrl_mux_sel_bypass_bundle ? vh[i+ndivBUS].q : mux_v_L1_seginfo;
        end
    end
end
endgenerate

// vh feeding
// dh data feeding 
generate
for(i=0;i<BLCKdivBUS;i=i+1) begin: d_assig_vh
    if(i<ndivBUS) begin
        assign vh[i].d = mux_v_bypass_bundle[i];
    end else begin
        assign vh[i].d = dig_bundle_data_validity[(i-ndivBUS)*BUSdiv8 +: BUSdiv8];
    end
end
endgenerate

// Output mux /////////////////////////
// L0 muxes layer 
wire [BUS_SIZE-1:0] mux_out_L0_dh [3:0];
wire [BUSdiv8-1:0] mux_out_L0_vh [3:0];
generate
for(i=0;i<4;i=i+1) begin: muxL0_out
    assign mux_out_L0_dh[i] = mux_out_ctrl[0] ? dh[2*i+1].q : dh[2*i].q;
    assign mux_out_L0_vh[i] = mux_out_ctrl[0] ? vh[2*i+1].q : vh[2*i].q;
end
endgenerate

// L1 muxes layer
wire [BUS_SIZE-1:0] mux_out_L1_dh [1:0];
wire [BUSdiv8-1:0] mux_out_L1_vh [1:0];
generate
for(i=0;i<2;i=i+1) begin: muxL1_out
    assign mux_out_L1_dh[i] = mux_out_ctrl[1] ? mux_out_L0_dh[2*i+1] : mux_out_L0_dh[2*i];
    assign mux_out_L1_vh[i] = mux_out_ctrl[1] ? mux_out_L0_vh[2*i+1] : mux_out_L0_vh[2*i];
end
endgenerate

// L0 muxes layer
wire [BUS_SIZE-1:0] mux_out_L2_dh = mux_out_ctrl[2] ? mux_out_L1_dh[1] : mux_out_L1_dh[0];
wire [BUSdiv8-1:0] mux_out_L2_vh = mux_out_ctrl[2] ? mux_out_L1_vh[1] : mux_out_L1_vh[0];

// Validity mask applier /////////////////
validity_mask_applier #(.BUS_SIZE(BUS_SIZE))
vma_core(
    .data_in(mux_out_L2_dh),
    .data_in_validity(mux_out_L2_vh),
    .data_out(data_out)
);

wire raw_data_out_valid = |(mux_out_L2_vh);
assign data_out_valid = unlock_validity & raw_data_out_valid ;
assign early_invalid = ~raw_data_out_valid;


endmodule
