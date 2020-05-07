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
(* fv_prop = "affine", fv_strat = "assumed", fv_order = d *)
module MSKregEn #(parameter d=1) (clk, rst, en, in, out);

	(* fv_type = "clock" *)   input clk;
	(* fv_type = "control" *) input rst;
	(* fv_type = "control" *) input en;
	(* fv_type = "sharing", fv_latency = 0 *) input  [d-1:0] in;
	(* fv_type = "sharing", fv_latency = 1 *) output [d-1:0] out;

	reg [d-1:0] state;
        always @(posedge rst, posedge clk)
        if(rst) 
            state <= 0;
        else
        if(en) begin
            state <= in;
        end else begin
            state <= state;
        end

        assign out = state;

endmodule
