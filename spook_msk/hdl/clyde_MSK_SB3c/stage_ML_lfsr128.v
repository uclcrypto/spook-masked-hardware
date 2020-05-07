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
    This module implement one stage of the 128-bits LFSR.
*/
module stage_ML_lfsr128
(
    input [127:0] in,
    output [127:0] out
);

wire feedback = ~(in[127] ^ in[125] ^ in[100] ^ in[98]);
assign out = {in[0 +: 127],feedback};

endmodule
