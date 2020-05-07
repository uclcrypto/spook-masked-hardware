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
    This module implements recursively a mux 
    with N entries of BUS_DATA_SIZE bits.
*/
module mux_gen
#
(
    parameter N = 7, // Amount of entries
    parameter BUS_DATA_SIZE = 1, // Bus size
    // Generation parameter (DO NOT TOUCH)
    parameter log2N = $clog2(N)
)
(
    input [N*BUS_DATA_SIZE-1:0]  data_in,
    input [(log2N-1):0] ctrl,
    output [BUS_DATA_SIZE-1:0]  data_out
);

// Sub muxes data sizes computations
localparam is2power = (2**log2N == N);
localparam amount_left = is2power ? N/2 : 2**(log2N-1); 
localparam amount_right = N - amount_left;

// Control bus size computation
parameter cs_left = $clog2(amount_left);
parameter cs_right = $clog2(amount_right);


generate
if(N==1) 
    assign data_out = data_in[BUS_DATA_SIZE-1:0];
else begin

    // Sub muxes data input
    wire [BUS_DATA_SIZE-1:0] from0,from1;

    // Left mux
    if (amount_left==1) begin
        assign from0 = data_in[BUS_DATA_SIZE-1:0];
    end else if(amount_left==2) begin
        assign from0 = ctrl[cs_left-1:0] ? data_in[2*BUS_DATA_SIZE-1:BUS_DATA_SIZE] : data_in[BUS_DATA_SIZE-1:0];
    end else begin
        mux_gen #(amount_left,BUS_DATA_SIZE) 
        mu_l(
            .data_in(data_in[BUS_DATA_SIZE*amount_left-1:0]),
            .ctrl(ctrl[cs_left-1:0]),
            .data_out(from0)
        );
    end

    // Right mux
    if (amount_right==1) begin
        assign from1 = data_in[(amount_left+1)*BUS_DATA_SIZE-1:amount_left*BUS_DATA_SIZE];
    end else if(amount_right==2) begin
        assign from1 = ctrl[cs_right-1:0] ? data_in[N*BUS_DATA_SIZE-1:(N-1)*BUS_DATA_SIZE] : data_in[(N-1)*BUS_DATA_SIZE-1:(N-2)*BUS_DATA_SIZE];
    end else begin 
        mux_gen #(amount_right,BUS_DATA_SIZE) 
        mu_r(
            .data_in(data_in[BUS_DATA_SIZE*amount_left+BUS_DATA_SIZE*amount_right-1:BUS_DATA_SIZE*amount_left]),
            .ctrl(ctrl[cs_right-1:0]),
            .data_out(from1)
        );
    end


    // Output assignation
    assign data_out = ctrl[log2N-1] ? from1 : from0;

end
endgenerate

endmodule
