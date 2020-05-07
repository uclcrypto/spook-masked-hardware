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
(* fv_prop = "affine", fv_strat = "isolate", fv_order = d *)
module MSKxor #(parameter d=2) (ina, inb, out);

	(* fv_type = "sharing", fv_latency = 0 *) input  [d-1:0] ina, inb;
	(* fv_type = "sharing", fv_latency = 0 *) output [d-1:0] out;

        //wire [d-1:0] t = ina ^ inb ;
        //assign out = {t[0],t[d-1:1]};
        assign out = ina ^ inb ;


endmodule
