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
    This module decodes a 32-bits command 
    considered as an header and outputs the 
    corresponding control signals.
*/
module header_decoder
(
    input [31:0] header,
    // Output
    // Infered header signals
    output head_valid,
    output seg_empty,
    // Real header decoded signals
    output [3:0] htype,
    output eot,
    output eoi,
    output last,
    output [15:0] length,
    output [3:0] sel_nibble
);

assign head_valid = header[16] & (header[19:17] == 3'b0);
assign length = header[15:0];
assign seg_empty = (length == 16'b0);
assign last = header[24];
assign eoi = header[25];
assign eot = header[26];
assign htype = header[31:28];
assign sel_nibble = header[23:20];



endmodule
