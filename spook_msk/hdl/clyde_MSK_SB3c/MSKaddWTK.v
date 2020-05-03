/*
    This module implements the logic to perform
    the tweakey and the W constant addition.
*/
(* fv_strat = "flatten" *)
module MSKaddWTK
#
(
parameter Nbits = 128,
parameter d = 2
)
(
    input [d*Nbits-1:0] sharing_bundle_in,
    input [d*Nbits-1:0] sharing_K,
    input [3:0] W,
    input [Nbits-1:0] delta,
    input ctrl_TK_addition,
    input ctrl_W_addition,
    output [d*Nbits-1:0] sharing_bundle_out
);


// Addition enabling mux //
// delta selection
wire [Nbits-1:0] ch_delta = ctrl_TK_addition ? delta : {Nbits{1'b0}};

// W selection
wire [3:0] ch_W = ctrl_W_addition ? W : 4'b0;

// Key selection
(* KEEP = "TRUE", S = "TRUE", DONT_TOUCH = "TRUE" *)
wire [d*Nbits-1:0] sharing_zero;
cst_mask #(.d(d),.count(Nbits))
cst_zero(
    .cst({Nbits{1'b0}}),
    .out(sharing_zero)
);

wire [d*Nbits-1:0] ch_sharing_K;
MSKmux_par #(.d(d),.count(Nbits))
mux_sh_K(
    .sel(ctrl_TK_addition),
    .in_true(sharing_K),
    .in_false(sharing_zero),
    .out(ch_sharing_K)
);

// W sharing generation //
wire [d*4-1:0] sharing_ch_W;
cst_mask #(.d(d),.count(4))
cst_sh_W(
    .cst(ch_W),
    .out(sharing_ch_W)
);

// delta sharing generation //
wire [d*Nbits-1:0] sharing_ch_delta;
cst_mask #(.d(d),.count(Nbits))
cst_sh_delta(
    .cst(ch_delta),
    .out(sharing_ch_delta)
);

// TK sharing generation //
wire [d*Nbits-1:0] sharing_TK;
MSKxor_par #(.d(d),.count(Nbits))
delta_xor_K(
    .ina(sharing_ch_delta),
    .inb(ch_sharing_K),
    .out(sharing_TK)
);

// W addition TODO add MSKxor_cst//
localparam SIZE_ROW_B = 32*d;

wire [d*Nbits-1:0] sharing_bundle_post_W;
genvar i;
generate
for(i=0;i<4;i=i+1) begin: WbitAdd
    MSKxor_par #(.d(d),.count(1))
    xor_Wb(
        .ina(sharing_bundle_in[SIZE_ROW_B*i +: d]),
        .inb(sharing_ch_W[d*i +: d]),
        .out(sharing_bundle_post_W[SIZE_ROW_B*i +: d])
    );
    assign sharing_bundle_post_W[SIZE_ROW_B*i+d +: SIZE_ROW_B-d] = sharing_bundle_in[SIZE_ROW_B*i+d +: SIZE_ROW_B-d];
end
endgenerate

// TK addition TODO: change with MSKxor_cst//
MSKxor_par #(.d(d),.count(Nbits))
xor_TK(
    .ina(sharing_bundle_post_W),
    .inb(sharing_TK),
    .out(sharing_bundle_out)
);

endmodule

