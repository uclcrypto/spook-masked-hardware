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
//////////////////////////////////////////////////////////////////////////////////
// Company: UCL-Crypto
// Engineer: Momin Charles
// 
// Create Date:    09:58:25 03/08/2019 
// Design Name: 
// Module Name:    sbox 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module sbox(
	input [3:0] in,
	output [3:0] out
);

/* PREVIOUS V2.0
wire [3:0] x;

assign x[0] = (in[1] & in[2]) ^ in[0];
assign x[3] = (x[0] & in[2]) ^ in[3];
assign x[2] = (in[1] & x[3]) ^ in[2];
assign x[1] = (x[0] & x[3]) ^ in[1];

assign out[0] = x[1];
assign out[1] = x[2];
assign out[2] = x[3];
assign out[3] = x[0];
*/

wire[3:0] y;

assign y[1] = (in[0] & in[1]) ^ in[2];
assign y[0] = (in[3] & in[0]) ^ in[1];
assign y[3] = (y[1]  & in[3]) ^ in[0];
assign y[2] = (y[0]  & y[1])  ^ in[3];

assign out[0] = y[0];
assign out[1] = y[1];
assign out[2] = y[2];
assign out[3] = y[3];

endmodule
