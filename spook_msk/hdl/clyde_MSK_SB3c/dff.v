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
    This module implements a D-flip flop. 
*/
module dff
#
(
    // Size (in bits)
    parameter SIZE =  1,
    // Reset strategy (ASYN=1 means asynchronous reset)
    parameter ASYN = 0,
    // Reset value
    parameter RST_V = 1'b0
)
(
    input clk,
    input rst,
    input [SIZE-1:0] d,
    input en,
    output [SIZE-1:0] q
);

reg [SIZE-1:0] flop;
wire [SIZE-1:0] next_flop;

assign q = flop; 

generate
if(ASYN) begin
    // Reg assignation
    always@(posedge rst, posedge clk)
    if(rst) begin
        flop <= RST_V;
    end else begin
        if(en) begin
            flop <= d;
        end else begin
				flop <= flop;
		  end
    end

end else begin
    // Reg assignation
    always@(posedge clk)
    if(rst) begin
        flop <= RST_V;
    end else begin
        if(en) begin
            flop <= d;
        end else begin
				flop <= flop;
		  end
    end

end
endgenerate

endmodule
