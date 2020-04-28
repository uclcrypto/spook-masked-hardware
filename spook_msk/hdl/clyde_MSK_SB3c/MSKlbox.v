/*
    This module implements the masked lbox operation.
*/
(* fv_prop = "PINI", fv_strat = "flatten", fv_order=d *)
module MSKlbox
#
(
    parameter d=2
)(x,y,a,b);

(* fv_type = "sharing", fv_latency = 0, fv_count=32 *)    
input    [32*d-1:0] x;
(* fv_type = "sharing", fv_latency = 0, fv_count=32 *)    
input     [32*d-1:0] y;
(* fv_type = "sharing", fv_latency = 0, fv_count=32 *)    
output    [32*d-1:0] a;
(* fv_type = "sharing", fv_latency = 0, fv_count=32 *)    
output  [32*d-1:0] b;

// Intermediate wires
wire [32*d-1:0] a0,a1,a2,a3;
wire [32*d-1:0] b0,b1,b2,b3;
wire [32*d-1:0] c,dd;

// Computation parts
MSKxor_par #(.d(d), .count(32)) 
MSKxor_par_inst1 (
    .ina(x), 
    .inb({x[12*d-1:0],x[32*d-1:12*d]}), 
    .out(a0)
);
MSKxor_par #(.d(d), .count(32)) 
MSKxor_par_inst2 (
    .ina(y), 
    .inb({y[12*d-1:0],y[32*d-1:12*d]}), 
    .out(b0)
);

MSKxor_par #(.d(d), .count(32)) 
MSKxor_par_inst3 (
    .ina(a0), 
    .inb({a0[3*d-1:0],a0[32*d-1:3*d]}), 
    .out(a1)
);
MSKxor_par #(.d(d), .count(32)) 
MSKxor_par_inst4 (
    .ina(b0), 
    .inb({b0[3*d-1:0],b0[32*d-1:3*d]}), 
    .out(b1)
);

MSKxor_par #(.d(d), .count(32)) 
MSKxor_par_inst5 (
    .ina(a1), 
    .inb({x[17*d-1:0],x[32*d-1:17*d]}), 
    .out(a2)
);
MSKxor_par #(.d(d), .count(32)) 
MSKxor_par_inst6 (
    .ina(b1), 
    .inb({y[17*d-1:0],y[32*d-1:17*d]}), 
    .out(b2)
);

MSKxor_par #(.d(d), .count(32)) 
MSKxor_par_inst7 (
    .ina(a2), 
    .inb({a2[31*d-1:0],a2[32*d-1:31*d]}), 
    .out(c)
);
MSKxor_par #(.d(d), .count(32)) 
MSKxor_par_inst8 (
    .ina(b2), 
    .inb({b2[31*d-1:0],b2[32*d-1:31*d]}), 
    .out(dd)
);

MSKxor_par #(.d(d), .count(32)) 
MSKxor_par_inst9 (
    .ina(a2), 
    .inb({dd[26*d-1:0],dd[32*d-1:26*d]}), 
    .out(a3)
);
MSKxor_par #(.d(d), .count(32)) 
MSKxor_par_inst10 (
    .ina(b2), 
    .inb({c[25*d-1:0],c[32*d-1:25*d]}), 
    .out(b3)
);

MSKxor_par #(.d(d), .count(32)) 
MSKxor_par_inst11 (
    .ina(a3), 
    .inb({c[15*d-1:0],c[32*d-1:15*d]}), 
    .out(a)
);
MSKxor_par #(.d(d), .count(32)) 
MSKxor_par_inst12 (
    .ina(b3), 
    .inb({dd[15*d-1:0],dd[32*d-1:15*d]}), 
    .out(b)
);

endmodule
