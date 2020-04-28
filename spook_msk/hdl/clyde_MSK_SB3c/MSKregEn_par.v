(* fv_strat = "flatten" *) module MSKregEn_par #(parameter d=1, parameter count=1) (clk, rst, en, in, out);

	(* fv_type = "clock" *)   input clk;
	(* fv_type = "control" *) input rst;
	(* fv_type = "control" *) input en;
	(* fv_type = "sharing", fv_latency = 0, fv_count=count *) input  [count*d-1:0] in;
	(* fv_type = "sharing", fv_latency = 1, fv_count=count *) output [count*d-1:0] out;

	genvar i;
	for(i=0; i<count; i=i+1) begin: regs
		MSKregEn #(d) rg(clk, rst, en, in[i*d +: d], out[i*d +: d]);
	end


endmodule
