// MLS DBOX (Spookv2.0)
module dbox_mls
(
    input [31:0] lfsr,
    input [31:0] x0,
    input [31:0] x1,
    input [31:0] x2,
    input [31:0] x3,
    output [31:0] y0,
    output [31:0] y1,
    output [31:0] y2,
    output [31:0] y3
);

wire [31:0] a = x0 ^ x1;
wire [31:0] b = x2 ^ x3;
wire [31:0] c = x1 ^ b;

wire [31:0] xta;
xtime
xt_a(
    .x_in(a),
    .x_out(xta)
);

wire [31:0] d = xta ^ x3;

wire [31:0] e;
xtime
xt_c(
    .x_in(c),
    .x_out(e)
);

wire [31:0] f = e ^ a;

wire [31:0] xtd;
xtime
xt_d(
    .x_in(d),
    .x_out(xtd)
);

wire [31:0] g = xtd ^ b;
wire [31:0] h = g ^ e;
wire [31:0] i = d ^ f;

assign y0 = f ^ lfsr;
assign y1 = h;
assign y2 = g;
assign y3 = i;

endmodule
