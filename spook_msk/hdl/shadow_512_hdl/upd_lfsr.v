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
   32-bits LFSR stage.
   Used to generate the constant values.
*/
module upd_lfsr
#
(
    parameter poly = 32'hc5
)
(
    input [31:0] lfsr_in,
    output [31:0] lfsr_out
);

wire [31:0] b_out_ext = lfsr_in[31] ? 32'hffffffff : 32'h0;
assign lfsr_out = (lfsr_in << 1) ^ (b_out_ext & poly);

endmodule
