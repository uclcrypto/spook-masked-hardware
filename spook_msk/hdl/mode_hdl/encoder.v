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
    Top module of the encoder.
*/
module encoder
#
(
    parameter BUS_SIZE = 32,
    parameter n = 128,
    parameter BLCK_SIZE = 256
)
(
    clk,
    syn_rst,
    // To/from external bus //
    data_out,
    data_out_valid,
    ready_ext,
    data_out_last,
    // Data to process //
    // Header/status data
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
    // Control signals from/to the controller //
    pre_send_header,
    send_header,
    pre_send_status,
    send_status,
    pre_send_tag,
    send_tag,
    unlock_dig_process,
    pre_pre_send_dig_data,
    pre_send_dig_data,
    send_dig_data,
    release_buffer,
    // Core status signal to controller //
    ready,
    pre_ready
);

// Generation params 
localparam BLCKdivBUS = BLCK_SIZE / BUS_SIZE;
localparam nd8 = n/8;

// IOs ports 
input clk;
input syn_rst;
output [BUS_SIZE-1:0] data_out;
output data_out_valid;
input ready_ext;
output data_out_last;
input [3:0] head_dtype;
input head_eot;
input head_eoi;
input head_last;
input [15:0] head_length;
input status_sel;
input [n-1:0] dig_bundle_data;
input [nd8-1:0] dig_bundle_data_validity;
input [n-1:0] tag_computed;
input pre_send_header;
input send_header;
input pre_send_status;
input send_status;
input pre_send_tag;
input send_tag;
input unlock_dig_process;
input pre_pre_send_dig_data;
input pre_send_dig_data;
input send_dig_data;
output release_buffer;
output ready;
output pre_ready;



// Interconnect. between internal controller and internal datapath
wire from_int_dp_early_invalid;
wire to_int_dp_ctrl_mux_sel_status;
wire to_int_dp_ctrl_mux_sel_seginfo;
wire to_int_dp_ctrl_mux_sel_bypass_bundle;
wire to_int_dp_enable_4H;
wire to_int_dp_enable_4L;
wire to_int_dp_unlock_validity;
wire [2:0] to_int_dp_ctrl_mux_out;

encoder_dp #(.BUS_SIZE(BUS_SIZE),.n(n),.BLCK_SIZE(BLCK_SIZE))
encoder_dp_core(
    .clk(clk),
    .head_dtype(head_dtype),
    .head_eot(head_eot),
    .head_eoi(head_eoi),
    .head_last(head_last),
    .head_length(head_length),
    .status_sel(status_sel),
    .dig_bundle_data(dig_bundle_data),
    .dig_bundle_data_validity(dig_bundle_data_validity),
    .tag_computed(tag_computed),
    .data_out_valid(data_out_valid),
    .data_out(data_out),
    .ctrl_mux_sel_status(to_int_dp_ctrl_mux_sel_status),
    .ctrl_mux_sel_seginfo(to_int_dp_ctrl_mux_sel_seginfo),
    .ctrl_mux_sel_bypass_bundle(to_int_dp_ctrl_mux_sel_bypass_bundle),
    .enable_4H(to_int_dp_enable_4H),
    .enable_4L(to_int_dp_enable_4L),
    .unlock_validity(to_int_dp_unlock_validity),
	 .mux_out_ctrl(to_int_dp_ctrl_mux_out),
    .early_invalid(from_int_dp_early_invalid)
);

encoder_ctrl #(.BUS_SIZE(BUS_SIZE),.BLCK_SIZE(BLCK_SIZE))
encoder_ctrl_core(
    .clk(clk),
    .syn_rst(syn_rst),
    .ready_ext(ready_ext),
    .pre_ready(pre_ready),
    .ready(ready),
    .pre_send_header(pre_send_header),
    .send_header(send_header),
    .pre_send_status(pre_send_status),
    .send_status(send_status),
    .pre_send_tag(pre_send_tag),
    .send_tag(send_tag),
    .unlock_dig_process(unlock_dig_process),
    .pre_pre_send_dig_data(pre_pre_send_dig_data),
    .pre_send_dig_data(pre_send_dig_data),
    .send_dig_data(send_dig_data),
    .release_buffer(release_buffer),
    .ctrl_mux_sel_status(to_int_dp_ctrl_mux_sel_status),
    .ctrl_mux_sel_seginfo(to_int_dp_ctrl_mux_sel_seginfo),
    .ctrl_mux_sel_bypass_bundle(to_int_dp_ctrl_mux_sel_bypass_bundle),
    .enable_4H(to_int_dp_enable_4H),
    .enable_4L(to_int_dp_enable_4L),
    .unlock_validity(to_int_dp_unlock_validity),
    .ctrl_mux_out(to_int_dp_ctrl_mux_out),
    .early_invalid(from_int_dp_early_invalid),
    .data_out_last(data_out_last)
);

endmodule



