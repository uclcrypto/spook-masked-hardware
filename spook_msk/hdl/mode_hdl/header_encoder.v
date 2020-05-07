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
    This module encodes a header to be sent
    in the communication protocole.
*/
module header_encoder
(
    input [3:0] dtype,
    input eot,
    input eoi,
    input last,
    input [15:0] length,
    // Encoded header
    output [31:0] header
);

assign header = {dtype,1'b0,eot,eoi,last,7'b0,1'b1,length};


endmodule
