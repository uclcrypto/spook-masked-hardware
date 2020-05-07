/*
    Copyright 2020 UCLouvain

    Licensed under the Solderpad Hardware Licence, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

        https://solderpad.org/licenses/SHL-2.0/

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/
/*
    This module generates a vector of ones of length corresponding
    to the value 'size_in' provided at the input. The output vector
    is padded with 0 to fill the remaining bits.
*/
module size2valid
#
(
    // Amount of bits for the size_in value
    parameter VALUE_SIZE = 3,  
    // Size of the output vectors 
    parameter BUS_OUT_SIZE = 4
)
(
    size_in,
    validity_out
);
// Generation parameters 
localparam VALID_AMOUNT = 2**(VALUE_SIZE);
localparam VALID_SIZE = VALID_AMOUNT-1;

// IOs
input [VALUE_SIZE-1:0] size_in;
output [BUS_OUT_SIZE-1:0] validity_out;

// Generate the valididy possibilities 
wire [VALID_SIZE*VALID_AMOUNT-1:0] valid_values;
wire [VALID_SIZE-1:0] selected_validity;

genvar i;
generate
for(i=0;i<VALID_AMOUNT;i=i+1) begin: valid_value_generation
    if(i==0) begin
        assign valid_values[i*VALID_SIZE +: VALID_SIZE] = 0;
    end else begin
        assign valid_values[i*VALID_SIZE +: VALID_SIZE] = {i{1'b1}};
    end
end
endgenerate

// Mux generation
mux_gen #(.N(VALID_AMOUNT),.BUS_DATA_SIZE(VALID_SIZE)) 
validity_mux(
    .data_in(valid_values),
    .ctrl(size_in),
    .data_out(selected_validity)
);

// Output trunctation
assign validity_out = selected_validity[VALID_SIZE-1:0];

endmodule
