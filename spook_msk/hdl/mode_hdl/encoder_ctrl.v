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
    This module is the controller of the
    module "encoder_dp".
*/
module encoder_ctrl
#
(
    parameter BUS_SIZE = 32,
    parameter BLCK_SIZE = 256
)
(
    clk,
    syn_rst,
    // From external core ready /////
    ready_ext,
    // The encoder is ready to receive new data to transmit
    pre_ready,
    ready,
    // Data sending from the controller
    pre_send_header,
    send_header,
    pre_send_status,
    send_status,
    pre_send_tag,
    send_tag,
    // The processing of digested block is enabled
    unlock_dig_process,
    // data to send
    pre_pre_send_dig_data,
    pre_send_dig_data,
    send_dig_data,
    release_buffer,
    // Control signals from/to the datapath ////
    ctrl_mux_sel_status,
    ctrl_mux_sel_seginfo,
    ctrl_mux_sel_bypass_bundle,
    enable_4H,
    enable_4L,
    unlock_validity,
    ctrl_mux_out,
    early_invalid,
    // The encoder output the last data related to an instruction
    data_out_last
);

// Generation params 
localparam BLCKdivBUS = BLCK_SIZE / BUS_SIZE;

// IOs ports 
input clk;
input syn_rst;
input ready_ext;
output pre_ready;
output ready;
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
output ctrl_mux_sel_status;
output ctrl_mux_sel_seginfo;
output ctrl_mux_sel_bypass_bundle;
output enable_4H;
output enable_4L;
output unlock_validity;
output [2:0] ctrl_mux_out;
input early_invalid;
output data_out_last;

////////////////////////////////
wire send_seginfo = send_header | send_status;
wire pre_send_seginfo = pre_send_header | pre_send_status;
wire actual_pre_send_dig_data = unlock_dig_process & pre_send_dig_data;
wire actual_send_dig_data = unlock_dig_process & send_dig_data;

// Mux control signals
assign ctrl_mux_sel_bypass_bundle = actual_send_dig_data | actual_pre_send_dig_data;
assign ctrl_mux_sel_seginfo = send_seginfo;
assign ctrl_mux_sel_status = send_status;

// Currently in progress flag
wire in_process;
wire end_in_proc_cnt;

assign unlock_validity = in_process;

wire set_in_process = send_seginfo | actual_send_dig_data | send_tag;
wire rst_in_process = syn_rst | (in_process & ready_ext & (early_invalid | end_in_proc_cnt));
wire next_in_process = (set_in_process | in_process);

dff #(.SIZE(1),.ASYN(0))
in_process_flag(
    .clk(clk),
    .rst(rst_in_process),
    .d(next_in_process),
    .en(1'b1),
    .q(in_process)
);

// Enable signal // 
wire en_H;
wire en_L;

assign enable_4H = en_H;
assign enable_4L = en_L;

wire set_en_H = (pre_pre_send_dig_data | pre_send_dig_data);
wire set_en_L = (pre_send_dig_data | pre_send_seginfo | pre_send_tag);

wire next_en_H = set_en_H & ~(next_in_process & ~rst_in_process);
wire next_en_L = set_en_L & ~(next_in_process & ~rst_in_process);

dff #(.SIZE(1),.ASYN(0))
en_H_reg(
    .clk(clk),
    .rst(syn_rst),
    .d(next_en_H),
    .en(1'b1),
    .q(en_H)
);

dff #(.SIZE(1),.ASYN(0))
en_L_reg(
    .clk(clk),
    .rst(syn_rst),
    .d(next_en_L),
    .en(1'b1),
    .q(en_L)
);

// In process counter max value //
wire [2:0] max_cnt_in_proc;
wire [2:0] next_max_cnt_in_proc = send_seginfo ? 3'd0 : (send_tag ? 3'd3 : 3'd7);
wire en_max_cnt_in_proc = (set_in_process & ~in_process) | syn_rst;

dff #(.SIZE(3),.ASYN(0))
max_cnt_reg(
    .clk(clk),
    .rst(syn_rst),
    .d(next_max_cnt_in_proc),
    .en(en_max_cnt_in_proc),
    .q(max_cnt_in_proc)
);

// In process counter //
wire [2:0] in_proc_cnt; 

assign ctrl_mux_out = in_proc_cnt;

assign end_in_proc_cnt = (in_proc_cnt == max_cnt_in_proc);
wire rst_in_proc_cnt = (set_in_process & ~in_process) | syn_rst;
wire en_in_proc_cnt = rst_in_proc_cnt | (in_process & ready_ext & (~end_in_proc_cnt));
wire [2:0] next_in_proc_cnt = in_proc_cnt + 3'b1;

dff #(.SIZE(3),.ASYN(0))
in_proc_cnt_reg(
    .clk(clk),
    .rst(rst_in_proc_cnt),
    .d(next_in_proc_cnt),
    .en(en_in_proc_cnt),
    .q(in_proc_cnt)
);

// ready flag
assign pre_ready = ~next_in_process;
assign ready = ~in_process;
assign release_buffer = send_dig_data;

// Data out last (to help FIFOs interface) //
wire rst_f_data_out_last = rst_in_process;
wire next_data_out_last = data_out_last | (send_status& ~in_process);

dff #(.SIZE(1),.ASYN(0))
flag_data_out_last(
    .clk(clk),
    .rst(rst_f_data_out_last),
    .d(next_data_out_last),
    .en(1'b1),
    .q(data_out_last)
);


endmodule
