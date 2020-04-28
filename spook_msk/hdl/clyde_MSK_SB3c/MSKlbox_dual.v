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
