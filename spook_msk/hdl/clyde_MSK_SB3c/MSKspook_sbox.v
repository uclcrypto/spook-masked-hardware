/*
    This module implement a masked spook sbox. 
*/
(* fv_prop = "PINI", fv_strat = "composite", fv_order=d *)
module MSKspook_sbox #(parameter d=4) (in, rnd1, rnd2, clk, out, enable);

`include "spook_sbox_rnd.inc"

(* fv_type = "sharing", fv_latency = 0, fv_count=spook_sbox_nbits*)
input  [d*spook_sbox_nbits-1:0] in;
(* fv_type = "sharing", fv_latency = spook_sbox_lat, fv_count=spook_sbox_nbits *)
output [d*spook_sbox_nbits-1:0] out;
(* fv_type = "clock" *) input clk;
(* fv_type = "random", fv_count=1, fv_rnd_lat_0=0, fv_rnd_count_0=2*and_pini_lat_1 *)
input [2*and_pini_lat_1-1:0] rnd1;
(* fv_type = "random", fv_count=1, fv_rnd_lat_0=1, fv_rnd_count_0=2*and_pini_lat_1 *)
input [2*and_pini_lat_1-1:0] rnd2;
(* fv_type = "control" *)
input enable;

// spook K4D2F2 --> depth 2 and 1 on one input of the 2nd layer and to reduce delay on refresh on the critical-path
wire [d-1:0] rfrs1, rfrs2, rfrs3, rfrs4, temp_out2, temp_out3;
// FF on the other AND input and synchronization/pipelining
(* KEEP = "TRUE" *)
(* DONT_TOUCH = "TRUE" *)
(* S = "TRUE" *)
wire [d-1:0] x0F, x1F, x2F, x1FF, x2FF, q1F, l1F, l1FF, l2F, q7F, l0F, l0FF, l0FFF, t2F, temp_out2F, temp_out3F;
wire  [d-1:0] l0, l1, l2, l3, l4, q1, q2, q5, q6, q7, t0, t1, t2, t3, l2xt2;

MSKregEn #(d) reg1 (clk, 1'b0, enable, in[d+d*(3)-1 -: d], x0F);//reversed input order
MSKregEn #(d) reg2 (clk, 1'b0, enable, in[d+d*(2)-1 -: d], x1F);//reversed input order
MSKregEn #(d) reg3 (clk, 1'b0, enable, x1F, x1FF);
MSKregEn #(d) reg4 (clk, 1'b0, enable, in[d+d*(1)-1 -: d], x2F);//reversed input order
MSKregEn #(d) reg5 (clk, 1'b0, enable, x2F, x2FF);
MSKregEn #(d) reg6 (clk, 1'b0, enable, q1, q1F);
MSKregEn #(d) reg7 (clk, 1'b0, enable, l1, l1F);
MSKregEn #(d) reg8 (clk, 1'b0, enable, l1F, l1FF);
MSKregEn #(d) reg10 (clk, 1'b0, enable, l2, l2F);
MSKregEn #(d) reg11 (clk, 1'b0, enable, q7, q7F);
MSKregEn #(d) reg12 (clk, 1'b0, enable, l0, l0F);
MSKregEn #(d) reg13 (clk, 1'b0, enable, l0F, l0FF);
MSKregEn #(d) reg14 (clk, 1'b0, enable, l0FF, l0FFF);
MSKregEn #(d) reg15 (clk, 1'b0, enable, t2, t2F);
MSKregEn #(d) reg16 (clk, 1'b0, enable, temp_out3, temp_out3F);
MSKregEn #(d) reg17 (clk, 1'b0, enable, temp_out2, temp_out2F);

MSKand_pini2 #(d) 
andg1(
    .inb(in[d+d*(0)-1 -: d]), 
    .ina(q1F), 
    .rnd(rnd1[0 +: and_pini_lat_1]),   
    .clk(clk), 
    .out(t0),
    .en(enable)
); //first input goes to be refreshed..

MSKand_pini2 #(d) 
andg2(
    .inb(x0F), 
    .ina(q2), 
    .rnd(rnd2[0 +: and_pini_lat_1]),  
    .clk(clk), 
    .out(t1),
    .en(enable)
); //first input goes to be refreshed..

MSKand_pini2 #(d) 
andg3(
    .inb(in[d+d*(0)-1 -: d]), 
    .ina(q5 ), 
    .rnd(rnd1[and_pini_lat_1 +: and_pini_lat_1]),  
    .clk(clk), 
    .out(t2),
    .en(enable)
); //first input goes to be refreshed..

MSKand_pini2 #(d) 
andg4(
    .inb(q7F), 
    .ina(q6), 
    .rnd(rnd2[and_pini_lat_1 +: and_pini_lat_1]),  
    .clk(clk), 
    .out(t3),
    .en(enable)
); //first input goes to be refreshed..

MSKinv #(d) invg1(.in(l0F), .out(q5));
MSKinv #(d) invg2(.in(l2xt2), .out(q6));

MSKxor #(d) xorg1(.ina(in[d+d*(1)-1 -: d]), .inb(in[d+d*(3)-1 -: d]), .out(q1));//reversed input order
MSKxor #(d) xorg2(.ina(in[d+d*(2)-1 -: d]), .inb(in[d+d*(3)-1 -: d]), .out(l1));//reversed input order
MSKxor #(d) xorg3(.ina(in[d+d*(0)-1 -: d]), .inb(in[d+d*(2)-1 -: d]), .out(q7));//reversed input order
MSKxor #(d) xorg4(.ina(in[d+d*(0)-1 -: d]), .inb(in[d+d*(3)-1 -: d]), .out(l0));//reversed input order
MSKxor #(d) xorg5(.ina(q1F),    .inb(q7F), .out(l2));
MSKxor #(d) xorg6(.ina(t0),     .inb(l1FF),.out(q2));
MSKxor #(d) xorg7(.ina(l2F),    .inb(t2),  .out(l2xt2));
MSKxor #(d) xorg8(.ina(t0),     .inb(t2),  .out(l3));
MSKxor #(d) xorg9(.ina(t1),     .inb(t2F), .out(l4));
MSKxor #(d) xorg10(.ina(l4),    .inb(t3),  .out(out[d+d*(2)-1 -: d]));       
MSKxor #(d) xorg11(.ina(l0FFF), .inb(l4),  .out(out[d+d*(3)-1 -: d]));       
MSKxor #(d) xorg12(.ina(x1FF),  .inb(l3),  .out(temp_out2));
MSKxor #(d) xorg13(.ina(x2FF),  .inb(t2),  .out(temp_out3));
assign out[d+d*(0)-1 -: d] = temp_out3F;
assign out[d+d*(1)-1 -: d] = temp_out2F;

endmodule

