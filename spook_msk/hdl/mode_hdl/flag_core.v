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
    This module implements the management of
    a flag signal
*/
module flag_core
(
    input clk,
    input rst,
    input syn_unset,
    input syn_set,
    output flag
);

wire en_update;
wire next_flag;

assign en_update = syn_unset | syn_set;
assign next_flag = syn_set & (~(syn_unset));

dff #(.SIZE(1),.ASYN(0))  
flag_reg(
    .clk(clk),
    .rst(rst),
    .d(next_flag),
    .en(en_update),
    .q(flag)
);


endmodule
