
(* fv_prop = "_mux", fv_strat = "assumed", fv_order = d *)
module MSKmux #(parameter d=1) (sel, in_true, in_false, out);

	(* fv_type = "control" *) input sel;
	(* fv_type = "sharing", fv_latency = 0 *) input  [d-1:0] in_true;
	(* fv_type = "sharing", fv_latency = 0 *) input  [d-1:0] in_false;
	(* fv_type = "sharing", fv_latency = 0 *) output [d-1:0] out;

	assign out = sel ? in_true : in_false;

endmodule