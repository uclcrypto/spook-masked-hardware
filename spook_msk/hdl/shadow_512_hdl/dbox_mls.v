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
// MLS DBOX (Spookv2.0)
module dbox_mls
(
    input [31:0] lfsr,
    input [31:0] x0,
    input [31:0] x1,
    input [31:0] x2,
    input [31:0] x3,
    output [31:0] y0,
    output [31:0] y1,
    output [31:0] y2,
    output [31:0] y3
);

wire [31:0] a = x0 ^ x1;
wire [31:0] b = x2 ^ x3;
wire [31:0] c = x1 ^ b;

wire [31:0] xta;
xtime
xt_a(
    .x_in(a),
    .x_out(xta)
);

wire [31:0] d = xta ^ x3;

wire [31:0] e;
xtime
xt_c(
    .x_in(c),
    .x_out(e)
);

wire [31:0] f = e ^ a;

wire [31:0] xtd;
xtime
xt_d(
    .x_in(d),
    .x_out(xtd)
);

wire [31:0] g = xtd ^ b;
wire [31:0] h = g ^ e;
wire [31:0] i = d ^ f;

assign y0 = f ^ lfsr;
assign y1 = h;
assign y2 = g;
assign y3 = i;

endmodule
