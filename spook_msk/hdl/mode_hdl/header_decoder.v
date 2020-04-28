/*
    This module decodes a 32-bits command 
    considered as an header and outputs the 
    corresponding control signals.
*/
module header_decoder
(
    input [31:0] header,
    // Output
    // Infered header signals
    output head_valid,
    output seg_empty,
    // Real header decoded signals
    output [3:0] htype,
    output eot,
    output eoi,
    output last,
    output [15:0] length,
    output [3:0] sel_nibble
);

assign head_valid = header[16] & (header[19:17] == 3'b0);
assign length = header[15:0];
assign seg_empty = (length == 16'b0);
assign last = header[24];
assign eoi = header[25];
assign eot = header[26];
assign htype = header[31:28];
assign sel_nibble = header[23:20];



endmodule
