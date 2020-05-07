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
    Top module of the phi computation module.
*/
module phi_unit_dual
(
    input clk,
    input [127:0] phi_in,
    input phi_in_valid,
    input inverse,
    output [127:0] phi_out,
    input enable
);

// phi register ///////////////
wire [127:0] phi;
wire [127:0] next_phi;
   
dff #(.SIZE(128),.ASYN(0))
phi_reg(
    .clk(clk),
    .rst(1'b0),
    .d(next_phi),
    .en(enable),
    .q(phi)
);

// feeding mux //
wire [127:0] feeding_phi = phi_in_valid ? phi_in : phi;

// phi update unit ////////////
wire [127:0] updated_phi;
phi_dual phi_comp_unit(
    .phi_in(feeding_phi),
    .inverse(inverse),
    .phi_out(updated_phi)
);

assign next_phi = updated_phi;

// Ouputs ////////////////////
assign phi_out = phi_in_valid ? phi_in : phi;

endmodule
