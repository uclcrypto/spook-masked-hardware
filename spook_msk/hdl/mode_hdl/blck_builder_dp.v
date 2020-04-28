/*
 Block builder datapath:
 Receive the input data block and builds a digested data block.
 The digested data block has a size (in bits) of BLCK_SIZE. If 
     the digested data stream has a length which is not a multiple of 
     BLCK_SIZE, the domain separation constant and the corresponding padding 
     is added.
*/
module blck_builder_dp
#
(
    parameter BUS_SIZE = 32, 
    parameter BLCK_SIZE = 256
)
(
    clk,
    rst,
    // Data relate inputs ///////////////////////
    // [DATA] Input data block.
    data_in,
    // [CNTRL] Input data block validity status.
    data_in_validity,
    // From controller //////////////////////////
    // [CNTRL]  If true, the domain separation constant has been already added.
    flag_cnst_add_done,
    // [CNTRL] If true, the buffer/validity values are updated at the next rising edge.
    en_update,
    // [CNTRL]  If true, the updating values comes from padding.
    en_padding,
    // Outputs //////////////////////////////////
    // [DATA] The digested data block.
    blck_out,
    // [CNTRL] The digested data block validity status.
    blck_out_validity
);

// Generation param
localparam BUSdiv8 = BUS_SIZE/8;
localparam BLCKdiv8 = BLCK_SIZE/8;

// IOs ports 
input clk;
input rst;
input [BUS_SIZE-1:0] data_in; 
input [BUSdiv8-1:0] data_in_validity; 
input flag_cnst_add_done; 
input en_update; 
input en_padding; 
output [BLCK_SIZE-1:0] blck_out; 
output [BLCKdiv8-1:0] blck_out_validity; 


// Buffer ////////////////////////////////////////
wire [BLCK_SIZE-1:0] buffer; // Handler of the data block that is currently built.  
wire [BLCK_SIZE-1:0] next_buffer; // next value of the data block (at the rising edge of the clock)

dff #(.SIZE(BLCK_SIZE),.ASYN(0)) 
buffer_reg( 
    .clk(clk),
    .rst(rst),
    .d(next_buffer),
    .en(en_update),
    .q(buffer)
);


// Loading value
wire [BUS_SIZE-1:0] loading_value; // Next value loaded to build the digested block.
wire [BLCK_SIZE-1:0] loaded_buffer_value; // Digested block under building with the loading value. 
assign loaded_buffer_value = {loading_value, buffer[BLCK_SIZE-1:BUS_SIZE]}; 

// Padding value 
wire [BUS_SIZE-1:0] padding_value; // Padding value used
assign padding_value = flag_cnst_add_done ? {BUS_SIZE{1'b0}} : {{(BUS_SIZE-1){1'b0}},1'b1};

wire [BLCK_SIZE-1:0] padded_buffer_value; // Digested block with the padding value.
assign padded_buffer_value = {padding_value, buffer[BLCK_SIZE-1:BUS_SIZE]};

// Next buffer logic:
//  When padding, the padded version of the buffer is used,
// else , the loaded version of the buffer is used. 
assign next_buffer = en_padding ? padded_buffer_value : loaded_buffer_value;

// Block validity ///////////////////////////////
wire [BLCKdiv8-1:0] blck_validity; // Output block byte validity
wire [BLCKdiv8-1:0] next_blck_validity; // next value of the byte validity

dff #(.SIZE(BLCKdiv8),.ASYN(0)) 
blck_validity_reg(
    .clk(clk),
    .rst(rst),
    .d(next_blck_validity),
    .en(en_update),
    .q(blck_validity)
); 

// Parametric dependant architecture ////////////
generate
if(BUSdiv8==1) begin
    // for 8-bit bus
    assign loading_value = data_in;
    // validity
    assign next_blck_validity = en_padding ? {1'b0,blck_validity[BLCKdiv8-1:1]} : {1'b1,blck_validity[BLCKdiv8-1:1]};

end else begin
    // for 16/32-bit bus
    // loading value formatter
    formatter #(.SIZE(BUS_SIZE)) 
    form_mod( 
        .data_raw(data_in),
        .data_validity(data_in_validity),
        .data_formatted(loading_value)
    ); 
    // validity
    assign next_blck_validity = en_padding ? {{BUSdiv8{1'b0}},blck_validity[BLCKdiv8-1:BUSdiv8]} : {data_in_validity,blck_validity[BLCKdiv8-1:BUSdiv8]};
end
endgenerate


// Outputs assignations //////////////////
assign blck_out = buffer;
assign blck_out_validity = blck_validity;

endmodule
