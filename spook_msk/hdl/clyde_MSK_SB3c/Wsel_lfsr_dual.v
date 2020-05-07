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
    This module computes the values of the 4-bits W constant, 
    either for encryption or decryption computation.
*/
module Wsel_lfsr_dual
(
    input clk,
    input syn_init,
    input inverse,
    output [3:0] Wout,
    input enable
);
// Constant for the reset
wire [3:0] W0 = 4'b0001;
wire [3:0] W10 = 4'b0111;
wire [3:0] W11 = 4'b1110;

wire [3:0] init_value = inverse ? W10 : W0;

// Holding registers //
wire [3:0] W;
wire [3:0] next_W;
dff #(.SIZE(4),.ASYN(0))
W_reg(
    .clk(clk),
    .rst(1'b0),
    .d(next_W),
    .en(enable),
    .q(W)
);

// Wupdate logic
wire [3:0] from_Winv, from_Wupd;
Winv winv_core(
    .W(W),
    .prevW(from_Winv)
);

Wupd wupd_core(
    .W(W),
    .nextW(from_Wupd)
);

wire [3:0] from_next = inverse ? from_Winv : from_Wupd;
assign next_W = syn_init ? init_value : from_next;
assign Wout = syn_init ? W11 : W;

endmodule
