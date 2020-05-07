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
(* fv_strat = "flatten" *)
module MSKmux_par #(parameter d=1, parameter count=1) (sel, in_true, in_false, out);

	input sel;
	input  [count*d-1:0] in_true;
	input  [count*d-1:0] in_false;
	output [count*d-1:0] out;

	genvar i;
	for(i=0; i<count; i=i+1) begin: muxes
		MSKmux #(d) mux(sel, in_true[i*d +: d], in_false[i*d +: d], out[i*d +: d]);
	end

endmodule
