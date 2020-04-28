/*
    This module apply a 'validity' mask over bytes of the data
    provided at its input. 
*/
module validity_mask_applier
#
(
    parameter BUS_SIZE = 32
)
(
    data_in,
    data_in_validity,
    data_out
);

// Generation params 
localparam BUSdiv8 = BUS_SIZE/8;

// IOs ports 
input [BUS_SIZE-1:0] data_in;
input [BUSdiv8-1:0] data_in_validity;
output [BUS_SIZE-1:0] data_out;


genvar i;
generate
for(i=0;i<BUSdiv8;i=i+1) begin: mask
    assign data_out[(i+1)*8-1:i*8] = data_in[(i+1)*8-1:i*8] & {8{data_in_validity[i]}};
end
endgenerate


endmodule
