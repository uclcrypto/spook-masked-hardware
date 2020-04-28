(* fv_prop = "affine", fv_strat = "assumed", fv_order = d *)
module MSKregEn #(parameter d=1) (clk, rst, en, in, out);

	(* fv_type = "clock" *)   input clk;
	(* fv_type = "control" *) input rst;
	(* fv_type = "control" *) input en;
	(* fv_type = "sharing", fv_latency = 0 *) input  [d-1:0] in;
	(* fv_type = "sharing", fv_latency = 1 *) output [d-1:0] out;

	reg [d-1:0] state;
        always @(posedge rst, posedge clk)
        if(rst) 
            state <= 0;
        else
        if(en) begin
            state <= in;
        end else begin
            state <= state;
        end

        assign out = state;

endmodule
