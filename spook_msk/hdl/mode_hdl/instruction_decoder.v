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
    This module decodes a 32-bits command
    considered as an instruction and outputs
    the corresponding control signals.
*/
module instruction_decoder
(
    // Inputs ////////////////////////
    // Input instruction.
    input [31:0] instr, 
    // Outputs ///////////////////////
    // Infered instr signals ////
    // The instruction is valid.
    output instr_valid, 
    // Real instr decoded signals ////
    // Decryption instruction flag.
    output decrypt, 
    // The key needs to be updated before processing other data.
    output key_update, 
    // The only operation made is updatting the key
    output key_only,
    // A seed value will be loaded
    output seed_update
);

localparam  ENC  = 4'b0010,
DEC  = 4'b0011,
LDKEY  = 4'b0100,
LDKEY_ENC = 4'b1001,
LDKEY_DEC = 4'b1010,
LD_SEED = 4'b1011;

wire [3:0] opcode;
assign opcode = instr[31:28];

assign instr_valid = ((opcode == ENC) | (opcode == DEC) | (opcode == LDKEY) | (opcode == LDKEY_ENC) | (opcode == LDKEY_DEC) |(opcode == LD_SEED)) & (instr[27:0] == 28'b0);
assign decrypt = (opcode == DEC) | (opcode == LDKEY_DEC);
assign key_update = (opcode == LDKEY) | (opcode == LDKEY_ENC) | (opcode == LDKEY_DEC);
assign key_only = (opcode == LDKEY);
assign seed_update = (opcode == LD_SEED);

endmodule
