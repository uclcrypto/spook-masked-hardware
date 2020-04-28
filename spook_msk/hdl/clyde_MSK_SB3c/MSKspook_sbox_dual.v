/*
    This module implements a dual spook sbox. The 'dual'
    means that the direct and the inverse operations are implemented.
*/
(* fv_strat = "flatten" *)
module MSKspook_sbox_dual #(parameter d=4) (in, rnd1, rnd2, clk, inverse, out, enable);

`include "spook_sbox_rnd.inc"

input [d*spook_sbox_nbits-1:0] in;
output [d*spook_sbox_nbits-1:0] out;
input inverse;
input clk;
input enable;

input [2*and_pini_lat_1-1:0] rnd1;
input [2*and_pini_lat_1-1:0] rnd2;

// Pre computation network for inverse ///// 
wire [d*spook_sbox_nbits-1:0] out_pre;
MSKpre_inv_sbox #(.d(d))
pre_stage(
    .in(in),
    .out(out_pre)
);

// x0, x1 latency registers to post computation network for inverse ///// 
genvar i;
generate 
for(i=0;i<spook_sbox_lat;i=i+1) begin: reg_barrier
    wire [2*d-1:0] in01d;
    wire [2*d-1:0] out01d;
    reg [2*d-1:0] regb;

    MSKregEn_par #(.d(d),.count(2))
    reg_b(
        .clk(clk),
        .rst(1'b0),
        .in(in01d),
        .out(out01d),
        .en(enable)
    );

    if(i==0) begin: IOs_assig
        assign in01d = in[0 +: 2*d];
    end else begin
        assign in01d = reg_barrier[i-1].out01d;
    end
end
endgenerate

// Input sbox core MSKmux /////
wire [d*spook_sbox_nbits-1:0] to_sbox_core;
MSKmux_par #(.d(d),.count(spook_sbox_nbits))
sb_mux_in(
    .sel(inverse),
    .in_true(out_pre),
    .in_false(in),
    .out(to_sbox_core)
);

// MSKspook_sbox core /////
wire [d*spook_sbox_nbits-1:0] from_sbox_core;
MSKspook_sbox #(.d(d))
sb_core(
    .in(to_sbox_core),
    .rnd1(rnd1),
    .rnd2(rnd2),
    .clk(clk),
    .out(from_sbox_core),
    .enable(enable)
);

// Post computation network for inverse /////
wire [d*spook_sbox_nbits-1:0] from_post_inv_sbox;
MSKpost_inv_sbox #(.d(d))
post_stage(
    .sin(from_sbox_core),
    .pin(reg_barrier[spook_sbox_lat-1].out01d),
    .out(from_post_inv_sbox)
);

// Output mux /////
MSKmux_par #(.d(d),.count(4))
out_mux(
    .sel(inverse),
    .in_true(from_post_inv_sbox),
    .in_false(from_sbox_core),
    .out(out)
);

endmodule
