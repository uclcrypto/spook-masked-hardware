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
    This module implement the phi operation and its inverse. 
    This operation is used in the tweakeys values computations.
*/
module phi_dual(
    input [127:0] phi_in,
    input inverse,
    output [127:0] phi_out
);

// temporary node
wire [63:0] t0,t1, tX;

// Computation
assign t0 = phi_in[63:0];
assign t1 = phi_in[127:64];
assign tX = t0 ^ t1;

// phi computation
assign phi_out = inverse ? {tX,t1} : {t0,tX};

endmodule
