/*
    This module encode a status 32-bits command.
*/
module status_encoder
(
    input status_sel,
    // outputs
    output [31:0] status
);

localparam  SUCCESS = 4'b1110,
FAILURE = 4'b1111;

wire [3:0] status_encoded = status_sel ? FAILURE : SUCCESS;

assign status = {status_encoded,28'b0};

endmodule
