/*
    This module implements the masked inverse lbox operation.
*/
(* fv_prop = "affine", fv_strat = "composite", fv_order=d *)
module MSKlbox_inv
#
(
    parameter d=2
)(x,y,a,b);

(* fv_type = "sharing", fv_latency = 0, fv_count=32 *)    
input [32*d-1:0] x;
(* fv_type = "sharing", fv_latency = 0, fv_count=32 *)    
input [32*d-1:0] y;
(* fv_type = "sharing", fv_latency = 0, fv_count=32 *)    
output [32*d-1:0] a;
(* fv_type = "sharing", fv_latency = 0, fv_count=32 *)    
output [32*d-1:0] b;

// Intermediate wires
wire [32*d-1:0] a0,a1,a2;
wire [32*d-1:0] b0,b1,b2;
wire [32*d-1:0] c0,c1,c2;
wire [32*d-1:0] d0,d1,d2;

MSKxor_par #(.d(d), .count(32)) 
MSKxor_par_inst1 (
    .ina(x), 
    .inb({x[25*d-1:0],x[32*d-1:25*d]}), 
    .out(a0)
);
MSKxor_par #(.d(d), .count(32)) 
MSKxor_par_inst2 (
    .ina(y), 
    .inb({y[25*d-1:0],y[32*d-1:25*d]}), 
    .out(b0)
);

MSKxor_par #(.d(d), .count(32)) 
MSKxor_par_inst3 (
    .ina(x), 
    .inb({a0[31*d-1:0],a0[32*d-1:31*d]}), 
    .out(c0)
);
MSKxor_par #(.d(d), .count(32)) 
MSKxor_par_inst4 (
    .ina(y), 
    .inb({b0[31*d-1:0],b0[32*d-1:31*d]}), 
    .out(d0)
);

MSKxor_par #(.d(d), .count(32)) 
MSKxor_par_inst5 (
    .ina(c0), 
    .inb({a0[20*d-1:0],a0[32*d-1:20*d]}), 
    .out(c1)
);
MSKxor_par #(.d(d), .count(32)) 
MSKxor_par_inst6 (
    .ina(d0), 
    .inb({b0[20*d-1:0],b0[32*d-1:20*d]}), 
    .out(d1)
);

MSKxor_par #(.d(d), .count(32)) 
MSKxor_par_inst7 (
    .ina(c1), 
    .inb({c1[31*d-1:0],c1[32*d-1:31*d]}), 
    .out(a1)
);
MSKxor_par #(.d(d), .count(32)) 
MSKxor_par_inst8 (
    .ina(d1), 
    .inb({d1[31*d-1:0],d1[32*d-1:31*d]}), 
    .out(b1)
);

MSKxor_par #(.d(d), .count(32)) 
MSKxor_par_inst9 (
    .ina(c1), 
    .inb({b1[26*d-1:0],b1[32*d-1:26*d]}), 
    .out(c2)
);
MSKxor_par #(.d(d), .count(32)) 
MSKxor_par_inst10 (
    .ina(d1), 
    .inb({a1[25*d-1:0],a1[32*d-1:25*d]}), 
    .out(d2)
);

MSKxor_par #(.d(d), .count(32)) 
MSKxor_par_inst11 (
    .ina(a1), 
    .inb({c2[17*d-1:0],c2[32*d-1:17*d]}), 
    .out(a2)
);
MSKxor_par #(.d(d), .count(32)) 
MSKxor_par_inst12 (
    .ina(b1), 
    .inb({d2[17*d-1:0],d2[32*d-1:17*d]}), 
    .out(b2)
);

assign a = {a2[16*d-1:0],a2[32*d-1:16*d]};
assign b = {b2[16*d-1:0],b2[32*d-1:16*d]};

endmodule
