/*
    Similar to the 'bundle2cols' module, but for sharing representation.
*/
(* fv_prop = "PINI", fv_strat = "composite", fv_order=d *)
module MSKbundle2cols
	#
	(
		parameter d = 2,    // Number of masking shares
		parameter Nbits = 128    // Number of state bits
	)(bundle_in, cols);

	(* fv_type = "sharing", fv_latency = 0, fv_count=Nbits *)    input    [Nbits*d-1:0]    bundle_in;
	(* fv_type = "sharing", fv_latency = 0, fv_count=Nbits *)    output    [Nbits*d-1:0]    cols;


	genvar i,j;
	generate
		for(i=0;i<(Nbits/4);i=i+1) begin: cols_division
			wire    [4*d-1:0]    col;
			assign col[d-1:0]       = bundle_in[d-1+i*d                : i*d               ];
			assign col[2*d-1:1*d] = bundle_in [d-1+i*d+(Nbits*d/4)    : i*d+(Nbits*d/4)   ];
			assign col[3*d-1:2*d] = bundle_in [d-1+i*d+(Nbits*d/4)*2  : i*d+(Nbits*d/4)*2 ];
			assign col[4*d-1:3*d] = bundle_in [d-1+i*d+(Nbits*d/4)*3  : i*d+(Nbits*d/4)*3 ];
			assign cols[(i+1)*4*d-1:i*4*d] = col;
		end
	endgenerate

endmodule
