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
    This module implements the LFSR used to
    generate the 32-bits constant for the Shadow primitive
*/
module lfsr_32
#(
    parameter poly = 32'hc5,
    parameter state_init = 32'hf8737400
)
(
    input clk,
    input n_syn_rst,
    input enable,
    output [31:0] lfsr_state
);

reg [31:0] state;
wire [31:0] nextstate;

upd_lfsr #(.poly(poly))
xt_lfsr(
    .lfsr_in(state),
    .lfsr_out(nextstate)
);

always@(posedge clk)
if(~n_syn_rst)
    state <= state_init;
else if(enable)
    state <= nextstate; 

assign lfsr_state = state;

endmodule
