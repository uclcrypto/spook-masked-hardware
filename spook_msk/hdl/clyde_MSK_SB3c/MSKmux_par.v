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
