/*
    This module implements multiple dual lboxes corresponding to 
    the serialisation parameter chosen.
*/
(* fv_prop = "PINI", fv_strat = "composite", fv_order=d *)
module MSKlbox_unit_dual
#
(
    parameter PDLBOX = 0,
    parameter Nbits = 128,    // Number of state bits.
    parameter d=2

)(bundle_in, bundle_out, inverse);

// Generation params (DO NOT TOUCH)
localparam AM_COLS_bund = 2**PDLBOX; // Amount of LB bundles
localparam SIZE_LBOX_bund = d*Nbits/AM_COLS_bund; // Size of LB bundles
localparam AM_LB = 2/AM_COLS_bund; // Amount of LB

(* fv_type = "sharing", fv_latency = 0, fv_count=Nbits/AM_COLS_bund *)
input    [SIZE_LBOX_bund-1:0]    bundle_in;
(* fv_type = "sharing", fv_latency = 0, fv_count=Nbits/AM_COLS_bund *)
output    [SIZE_LBOX_bund-1:0]    bundle_out;
(* fv_type = "control" *)
input inverse;

genvar i;
generate
for(i=0;i<AM_LB;i=i+1) begin: lb
    MSKlbox_dual #(.d(d))    
    lbi(
        .inverse(inverse),
        .x(bundle_in [32*d-1+64*d*i:64*d*i]),
        .y(bundle_in [64*d-1+64*d*i:32*d+64*d*i]),
        .a(bundle_out[32*d-1+64*d*i:64*d*i]),
        .b(bundle_out[64*d-1+64*d*i:32*d+64*d*i])
    );
end
endgenerate

endmodule
