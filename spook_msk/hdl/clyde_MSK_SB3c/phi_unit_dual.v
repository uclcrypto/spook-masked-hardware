/*
    Top module of the phi computation module.
*/
module phi_unit_dual
(
    input clk,
    input [127:0] phi_in,
    input phi_in_valid,
    input inverse,
    output [127:0] phi_out,
    input enable
);

// phi register ///////////////
wire [127:0] phi;
wire [127:0] next_phi;
   
dff #(.SIZE(128),.ASYN(0))
phi_reg(
    .clk(clk),
    .rst(1'b0),
    .d(next_phi),
    .en(enable),
    .q(phi)
);

// feeding mux //
wire [127:0] feeding_phi = phi_in_valid ? phi_in : phi;

// phi update unit ////////////
wire [127:0] updated_phi;
phi_dual phi_comp_unit(
    .phi_in(feeding_phi),
    .inverse(inverse),
    .phi_out(updated_phi)
);

assign next_phi = updated_phi;

// Ouputs ////////////////////
assign phi_out = phi_in_valid ? phi_in : phi;

endmodule
