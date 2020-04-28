/* 
 Interface decoder:
 Receive the inputs commands ; decode these and hold the last 
 status received for the instructions and the headers.

*/
module decoder
#
(
    parameter BUS_SIZE = 32
)
(
    clk,
    rst,
    // Commands bus /////////////////////////////////////////
    // [DATA] The input command.
    data_in,
    // [CNTRL] The input command is valid.
    data_in_valid,
    // [CNTRL] The core is ready to receive new command.
    ready,
    // Ciphercore ///////////////////////////////////////////
    // [CNTRL] The controller is expecting a new instruction.
    from_cntrl_rdy_instr_fetch,
    // [CNTRL] The controller is expecting a new header.
    from_cntrl_rdy_head_fetch,
    // [CNTRL] The controller is expecting data. 
    from_cntrl_rdy_data_fetch,
    // Instruction related signals //////////////////////////
    // Instruction decoded signals
    // [CNTRL] Infered signal. The command received is a valid instruction.
    to_cntrl_instruction_valid,
    // [CNTRL] Infered signal. Decryption instruction flag.
    to_cntrl_decrypt,
    // [CNTRL] Infered signal. The key needs to be updated before processing other data.
    to_cntrl_key_update,
    // [CNTRL] Infered signal. The only operation made is updatting the key.
    to_cntrl_key_only,
    to_cntrl_seed_update,
    // Header related signals ///////////////////////////////
    // Header decoded signals 
    // [CNTRL] Infered signal. The command received is a valid header.
    to_cntrl_header_valid,
    // [CNTRL] Header segment data type value.
    to_cntrl_dtype, 
    // [CNTRL] Header end of type flag.
    to_cntrl_eot,
    // [CNTRL] Header end of inputs flag (currently not used).
    to_cntrl_eoi,
    // [CNTRL] Header last flag (currently not used).
    //output to_cntrl_last, 
    // [CNTRL] Header segment length value.
    to_cntrl_length, 
    // Header infered signals ///////////////////////////////
    // [CNTRL] Infered signal. The segment related to the last received header is empty.
    to_cntrl_seg_empty, 
    to_cntrl_sel_nibble,
    // Data related signals /////////////////////////////////
    // [DATA] Infered signal. A data block related to the last received header.
    to_dp_data_out, 
    // [CNTRL] The command received is a valid and expected data block.  
    to_cntrl_data_out_valid, 
    // [CNTRL] The data block validity status [1 bit per byte, 1 means valid].
    to_dp_data_out_validity, 
    // [CNTRL] Infered signal. The data block contains non valid data.
    to_cntrl_data_out_partial, 
    // [CNTRL] Infered signal. The data block is the last of the current segment.
    to_cntrl_data_out_last_of_seg 
);


// Generation params 
localparam BUSdiv8 = BUS_SIZE/8;

// IOs 
input clk;
input rst;
input [BUS_SIZE-1:0] data_in;
input data_in_valid; 
output ready; 
input from_cntrl_rdy_instr_fetch; 
input from_cntrl_rdy_head_fetch; 
input from_cntrl_rdy_data_fetch; 
output to_cntrl_instruction_valid; 
output to_cntrl_decrypt; 
output to_cntrl_key_update; 
output to_cntrl_key_only; 
output to_cntrl_seed_update;
output to_cntrl_header_valid; 
output [3:0] to_cntrl_dtype; 
output to_cntrl_eot; 
output to_cntrl_eoi; 
output [15:0] to_cntrl_length; 
output to_cntrl_seg_empty; 
output [3:0] to_cntrl_sel_nibble;
output [BUS_SIZE-1:0] to_dp_data_out; 
output to_cntrl_data_out_valid; 
output [BUSdiv8-1:0] to_dp_data_out_validity; 
output to_cntrl_data_out_partial; 
output to_cntrl_data_out_last_of_seg;

// INSTRUCTION control management //////////////////// 
// INSTR decoder
wire instr_valid_dec;
wire decrypt_dec;
wire key_update_dec;
wire key_only_dec;
wire seed_update_dec;

instruction_decoder 
instr_dec(
    .instr(data_in),
    .instr_valid(instr_valid_dec),
    .decrypt(decrypt_dec),
    .key_update(key_update_dec),
    .key_only(key_only_dec),
    .seed_update(seed_update_dec)
); 

assign to_cntrl_instruction_valid = instr_valid_dec & data_in_valid;

// INSTR memory
// Allows to hold the signals related to the last received instruction
wire  en_instr_mem;
wire [3:0] to_instr_mem; 
wire [3:0] instr_mem; 

assign to_instr_mem = {seed_update_dec,decrypt_dec,key_update_dec,key_only_dec};
assign en_instr_mem = from_cntrl_rdy_instr_fetch;

dff #(.SIZE(4)) 
instr_mem_reg(.clk(clk),
    .rst(rst),
    .d(to_instr_mem),
    .en(en_instr_mem),
    .q(instr_mem)
);

// INSTR signals output; 
// Here, the muxes are required to directly feed fresh signals when a valid command are provided.
// This is required by the controller FSM, but can be easily modified by adding a buffer state
// after the WAIT_INST state.
assign to_cntrl_seed_update = (to_cntrl_instruction_valid & from_cntrl_rdy_instr_fetch) ? seed_update_dec : instr_mem[3];
assign to_cntrl_decrypt = (to_cntrl_instruction_valid & from_cntrl_rdy_instr_fetch) ? decrypt_dec : instr_mem[2];
assign to_cntrl_key_update = (to_cntrl_instruction_valid & from_cntrl_rdy_instr_fetch) ? key_update_dec : instr_mem[1];
assign to_cntrl_key_only = (to_cntrl_instruction_valid & from_cntrl_rdy_instr_fetch) ? key_only_dec : instr_mem[0];


// HEADER control management /////////////////////
// HEADER decoder
wire head_valid_dec;
wire seg_empty_dec;
wire [3:0] type_dec;
wire eot_dec;
wire  eoi_dec;
wire last_dec;
wire [15:0] length_dec;
wire [3:0] sel_nibble_dec;

header_decoder 
head_dec(
    .header(data_in),
    .head_valid(head_valid_dec),
    .seg_empty(seg_empty_dec),
    .htype(type_dec),
    .eot(eot_dec),
    .eoi(eoi_dec),
    .last(last_dec),
    .length(length_dec),
    .sel_nibble(sel_nibble_dec)
);

assign to_cntrl_header_valid = head_valid_dec & data_in_valid;

// HEADER memory
// Allows to hold the signals related to the last received header
wire en_head_mem;
wire [27:0] to_head_mem;
wire [27:0] head_mem;
wire [15:0] length_mem;

assign to_head_mem = {sel_nibble_dec,seg_empty_dec,type_dec,eot_dec,eoi_dec,last_dec,length_dec};
assign en_head_mem = from_cntrl_rdy_head_fetch;

dff #(.SIZE(28),.ASYN(0)) 
head_mem_reg(
    .clk(clk),
    .rst(rst),
    .d(to_head_mem),
    .en(en_head_mem),
    .q(head_mem)
);


// LENGTH COUNTER
// Countdown the amount of remaining bytes in the segment to receive,
// and so the amount of remaining data blocks in the segment. 
wire rst_syn_len_cnt;
wire en_len_cnt;
wire [15:0] to_len_cnt;
wire [15:0] len_cnt;

assign rst_syn_len_cnt = to_cntrl_header_valid & from_cntrl_rdy_head_fetch;
assign en_len_cnt =  (from_cntrl_rdy_data_fetch & data_in_valid) | rst_syn_len_cnt;             
assign to_len_cnt = rst_syn_len_cnt ? length_dec : len_cnt - BUSdiv8;

dff #(.SIZE(16)) 
len_cnt_reg( 
    .clk(clk),
    .rst(rst),
    .d(to_len_cnt),
    .en(en_len_cnt),
    .q(len_cnt)
);

// HEAD signals output
// Here, the muxes are required to directly feed fresh signals when a valid command are provided.
// This is required by the controller FSM, but can be easily modified by adding a buffer state
// after the WAIT_KEY, WAIT_NONCE, WAIT_D and WAIT_TAG state.
assign to_cntrl_sel_nibble = (to_cntrl_header_valid & from_cntrl_rdy_head_fetch) ? sel_nibble_dec : head_mem[27:24];
assign to_cntrl_seg_empty = (to_cntrl_header_valid & from_cntrl_rdy_head_fetch) ? seg_empty_dec : head_mem[23]; 
assign to_cntrl_dtype = (to_cntrl_header_valid & from_cntrl_rdy_head_fetch) ? type_dec : head_mem[22:19];
assign to_cntrl_eot = (to_cntrl_header_valid & from_cntrl_rdy_head_fetch) ? eot_dec : head_mem[18];
assign to_cntrl_eoi = (to_cntrl_header_valid & from_cntrl_rdy_head_fetch) ? eoi_dec : head_mem[17];
//assign to_cntrl_last = (to_cntrl_header_valid & from_cntrl_rdy_head_fetch) ? last_dec : head_mem[16];
assign to_cntrl_length = (to_cntrl_header_valid & from_cntrl_rdy_head_fetch) ? length_dec : head_mem[15:0];

wire to_cntrl_last_data_in_seg = (len_cnt <= BUSdiv8);

// DATA signals output /////////////////////////
assign to_dp_data_out = data_in;
// The rdy_data_fetch signal to be sure that data handler do not 
// use instruction or header as data.
assign to_cntrl_data_out_valid = data_in_valid & from_cntrl_rdy_data_fetch; 

// Data validity
// The data validity is derived from the bytes remaining in the segment 
// currently processed. 
parameter VALUE_SIZE_VAL = $clog2(BUSdiv8)+1; // Size (in bits) of valid bytes amount in the data block outputted.
wire [VALUE_SIZE_VAL-1:0] value_to_size; // valid bytes amount.
wire [BUSdiv8-1:0] data_validity; // Data block validity status.

// Module generating valididty signal based on the valid bytes amount
assign value_to_size = to_cntrl_last_data_in_seg ? len_cnt[VALUE_SIZE_VAL-1:0] : {VALUE_SIZE_VAL{1'b1}};
size2valid #(.VALUE_SIZE(VALUE_SIZE_VAL),.BUS_OUT_SIZE(BUSdiv8)) s2v_one_hot(value_to_size,data_validity);


assign to_dp_data_out_validity = data_validity;
assign to_cntrl_data_out_last_of_seg = to_cntrl_last_data_in_seg & to_cntrl_data_out_valid & from_cntrl_rdy_data_fetch;
assign to_cntrl_data_out_partial = to_cntrl_data_out_last_of_seg ? |(~(data_validity)) : 1'b0;

// General outputs ////////
assign ready = from_cntrl_rdy_instr_fetch | from_cntrl_rdy_head_fetch | from_cntrl_rdy_data_fetch;

endmodule
