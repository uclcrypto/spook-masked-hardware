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
    This module implement a masked dual sbox. The 'dual'
    means that both the direct and inverse operations are implemented.
*/
(* fv_prop = "PINI", fv_strat = "flatten", fv_order=d *)
module MSKlbox_dual
#
(
    parameter d=2
)
(
    (* fv_type = "sharing", fv_latency = 0, fv_count=32 *)    
    input    [32*d-1:0] x,
    (* fv_type = "sharing", fv_latency = 0, fv_count=32 *)    
    input     [32*d-1:0] y,
    (* fv_type = "sharing", fv_latency = 0, fv_count=32 *)    
    output    [32*d-1:0] a,
    (* fv_type = "sharing", fv_latency = 0, fv_count=32 *)    
    output  [32*d-1:0] b,
    (* fv_type = "control" *)
    input inverse
);

wire [32*d-1:0] a_lb, b_lb;
wire [32*d-1:0] a_lb_inv, b_lb_inv;

MSKlbox #(.d(d))
lbox_core(
    .x(x),
    .y(y),
    .a(a_lb),
    .b(b_lb)
);

MSKlbox_inv #(.d(d))
lbox_inv_core(
    .x(x),
    .y(y),
    .a(a_lb_inv),
    .b(b_lb_inv)
);

MSKmux_par #(.d(d),.count(32))
mux_a(
    .sel(inverse),
    .in_true(a_lb_inv),
    .in_false(a_lb),
    .out(a)
);

MSKmux_par #(.d(d),.count(32))
mux_b(
    .sel(inverse),
    .in_true(b_lb_inv),
    .in_false(b_lb),
    .out(b)
);


endmodule
