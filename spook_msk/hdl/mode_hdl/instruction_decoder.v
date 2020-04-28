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
