//////////////////////////////////////////////////////////////////////////////////
// Company: UCL-Crypto
// Engineer: Momin Charles
// 
// Create Date:    11:42:06 03/08/2019 
// Design Name: 
// Module Name:    lbox 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module lbox(
	input    [31:0] x,
	input     [31:0] y,
	output    [31:0] a,
	output   [31:0] b
);

// Intermediate wires
wire [31:0] a0,a1,a2,a3;
wire [31:0] b0,b1,b2,b3;
wire [31:0] c,d;

// Computation parts
assign a0 = x ^ {x[11:0],x[31:12]}; 
assign b0 = y ^ {y[11:0],y[31:12]};

assign a1 = a0 ^ {a0[2:0],a0[31:3]};
assign b1 = b0 ^ {b0[2:0],b0[31:3]};

assign a2 = a1 ^ {x[16:0],x[31:17]}; 
assign b2 = b1 ^ {y[16:0],y[31:17]};

assign c = a2 ^ {a2[30:0],a2[31]};
assign d = b2 ^ {b2[30:0],b2[31]};

assign a3 = a2 ^ {d[25:0],d[31:26]};
assign b3 = b2 ^ {c[24:0],c[31:25]};

assign a = a3 ^ {c[14:0],c[31:15]};
assign b = b3 ^ {d[14:0],d[31:15]};

endmodule
