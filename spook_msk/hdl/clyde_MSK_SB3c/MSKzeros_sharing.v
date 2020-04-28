/*
    This module produce a valid sharing for a vector of 0.
*/
(* fv_prop = "PINI", fv_strat = "assumed", fv_order = d *)
module MSKzeros_sharing
#
(
    parameter d = 2,
    parameter Nbits = 128
)
(
    (* fv_type = "random", fv_count = 1, fv_rnd_lat_0 = 0, fv_rnd_count_0 = Nbits *)
    input [(d-1)*Nbits-1:0] rnd,
    (* fv_type = "sharing", fv_latency = 0, fv_count = Nbits *)
    output [d*Nbits-1:0] zeros
);

genvar i,b;
generate 
for(i=0;i<d-1;i=i+1) begin: generated_sharing
    assign zeros[i*Nbits +: Nbits] = rnd[i*Nbits +: Nbits];
end
endgenerate

generate
for(b=0;b<Nbits;b=b+1) begin: last_share_bit
    wire [d-1-1:0] bit_shares;
    for(i=0;i<d-1;i=i+1) begin: prev_shares
        assign bit_shares[i] = zeros[i*Nbits+b];       
    end
    assign zeros[(d-1)*Nbits + b] = ^(bit_shares);
end
endgenerate

endmodule
