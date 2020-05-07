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
    This module implements the logic to 
    compute the value of the 4-bits constant 
    during the a decryption computation.
*/
module Winv(
    input [3:0] W,
    output [3:0] prevW
);

wire pad_with_1 = W[0];
wire [3:0] term0 = pad_with_1 ? 4'b1000 : 4'b0000;
wire [3:0] term1 = pad_with_1 ? 4'b0011 : 4'b0000;
wire [3:0] shifted_r_W = (W ^ term1) >> 1;

assign prevW = shifted_r_W ^ term0;


endmodule
