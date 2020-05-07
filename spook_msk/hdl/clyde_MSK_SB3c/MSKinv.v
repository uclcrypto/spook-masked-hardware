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
    Not gate for sharing.
*/
(* fv_prop = "affine", fv_strat = "assumed", fv_order = d *) 
module MSKinv #(parameter d=2) (in, out);

	(* fv_type = "sharing", fv_latency = 0, fv_count=1 *) input  [d-1:0] in;
	(* fv_type = "sharing", fv_latency = 0, fv_count=1 *) output [d-1:0] out;

	assign out[d-1:0] = {in[d-1:1],~in[0]};

endmodule
