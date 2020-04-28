/*
    Not gate for sharing.
*/
(* fv_prop = "affine", fv_strat = "assumed", fv_order = d *) 
module MSKinv #(parameter d=2) (in, out);

	(* fv_type = "sharing", fv_latency = 0, fv_count=1 *) input  [d-1:0] in;
	(* fv_type = "sharing", fv_latency = 0, fv_count=1 *) output [d-1:0] out;

	assign out[d-1:0] = {in[d-1:1],~in[0]};

endmodule
