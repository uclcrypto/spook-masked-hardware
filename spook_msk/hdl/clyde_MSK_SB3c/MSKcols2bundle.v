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
    Similar to the 'cols2bundle' module, but for sharings representation.
*/
(* fv_strat = "flatten" *)
module MSKcols2bundle
	#
	(
		parameter d = 2,    // Number of masking shares
		parameter Nbits = 128    // Number of state bits
	)(cols, bundle_out);

	(* fv_type = "sharing", fv_latency = 0, fv_count=Nbits *)    input    [Nbits*d-1:0]    cols;
	(* fv_type = "sharing", fv_latency = 0, fv_count=Nbits *)    output    [Nbits*d-1:0]    bundle_out;

	genvar i,j;
	generate
		for(i=0;i<(Nbits/4);i=i+1) begin: cols_division
			wire    [4*d-1:0]    col;
			assign col = cols[(i+1)*4*d-1:i*4*d];
			assign bundle_out[d-1+i*d              : i*d              ] = col[d-1:0];
			assign bundle_out[d-1+i*d+(Nbits*d/4)  : i*d+(Nbits*d/4)  ] = col[2*d-1:1*d];
			assign bundle_out[d-1+i*d+(Nbits*d/4)*2: i*d+(Nbits*d/4)*2] = col[3*d-1:2*d];
			assign bundle_out[d-1+i*d+(Nbits*d/4)*3: i*d+(Nbits*d/4)*3] = col[4*d-1:3*d];
		end
	endgenerate

endmodule
