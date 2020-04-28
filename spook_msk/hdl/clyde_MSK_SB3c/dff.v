/*
    This module implements a D-flip flop. 
*/
module dff
#
(
    // Size (in bits)
    parameter SIZE =  1,
    // Reset strategy (ASYN=1 means asynchronous reset)
    parameter ASYN = 0,
    // Reset value
    parameter RST_V = 1'b0
)
(
    input clk,
    input rst,
    input [SIZE-1:0] d,
    input en,
    output [SIZE-1:0] q
);

reg [SIZE-1:0] flop;
wire [SIZE-1:0] next_flop;

assign q = flop; 

generate
if(ASYN) begin
    // Reg assignation
    always@(posedge rst, posedge clk)
    if(rst) begin
        flop <= RST_V;
    end else begin
        if(en) begin
            flop <= d;
        end else begin
				flop <= flop;
		  end
    end

end else begin
    // Reg assignation
    always@(posedge clk)
    if(rst) begin
        flop <= RST_V;
    end else begin
        if(en) begin
            flop <= d;
        end else begin
				flop <= flop;
		  end
    end

end
endgenerate

endmodule
