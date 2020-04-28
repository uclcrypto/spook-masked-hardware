(* fv_prop = "affine", fv_strat = "isolate", fv_order = d *)
module MSKxor #(parameter d=2) (ina, inb, out);

	(* fv_type = "sharing", fv_latency = 0 *) input  [d-1:0] ina, inb;
	(* fv_type = "sharing", fv_latency = 0 *) output [d-1:0] out;

        //wire [d-1:0] t = ina ^ inb ;
        //assign out = {t[0],t[d-1:1]};
        assign out = ina ^ inb ;


endmodule
