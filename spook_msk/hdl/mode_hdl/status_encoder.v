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
