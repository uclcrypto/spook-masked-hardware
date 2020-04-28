/*
    This module is used to properly process the digested
    data during a decryption process.
*/
module decrypt_dig_blck_formatter
#(
    parameter BLCK_SIZE = 256
)
(
    dig_blck_in,
    dig_blck_in_validity,
    feed_blck_in,
    dec_dig_blck_out   
);

// Generation param //
localparam BLCKdiv8 = BLCK_SIZE/8;

// IOs ports 
input [BLCK_SIZE-1:0] dig_blck_in;
input [BLCKdiv8-1:0] dig_blck_in_validity;
input [BLCK_SIZE-1:0] feed_blck_in;
output [BLCK_SIZE-1:0] dec_dig_blck_out;


genvar i;
generate
for(i=0;i<BLCKdiv8;i=i+1) begin: mux
    assign dec_dig_blck_out[i*8 +: 8] = dig_blck_in_validity[i] ? dig_blck_in[i*8 +: 8] : feed_blck_in[i*8 +: 8] ^ dig_blck_in[i*8 +: 8];
end
endgenerate


endmodule
