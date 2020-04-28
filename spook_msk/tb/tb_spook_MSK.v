`timescale 1ns / 1ps
module tb_spook_MSK();

localparam Tclk = 10;
localparam Tclkd = (Tclk/2.0);

// File reading ///////////
// FDs
integer 	infile, outfile;
integer count_r,counter_i;

// Output file management ///////////////////
integer case_id_counter = 1;

// reading buffer ////////////////////////
reg	[9*8-1:0]	read;

wire	[23:0] newID_string;
wire	[31:0] endFile_string;
assign newID_string = 24'h3d4944;
assign endFile_string = 32'h23232323;

reg end_file;

reg end_case;
reg nextdata_valid;
wire bus_out_last;

integer received_ack;

// read instruction
reg	[31:0]	instruction;

// clk
reg	clk;
always@(*) #Tclkd clk<=~clk;

// dut signal
reg rst;

wire	[31:0]	com_bus_in;
reg				com_bus_in_valid;
wire				com_bus_in_ready;

wire	[31:0]	com_bus_out;
wire				com_bus_out_valid;
wire com_bus_out_ready = 1;

assign com_bus_in = instruction;

// dut
`ifdef behavioral
spook_MSK 
#(
    .d(`DSHARE),
    .PDSBOX(`PDSBOX),
    .PDLBOX(`PDLBOX)
)
`else
spook_MSK 
#(
    .d(`DSHARE),
    .PDSBOX(`PDSBOX),
    .PDLBOX(`PDLBOX)
) 
`endif
dut(.clk(clk),
    .rst(rst),
    .bus_in(com_bus_in),
    .bus_in_valid(com_bus_in_valid),
    .ready_bus_in(com_bus_in_ready),
    .bus_out(com_bus_out),
    .bus_out_valid(com_bus_out_valid),
    .ready_bus_out(com_bus_out_ready),
    .bus_out_last(bus_out_last)
);

`ifndef DUMP_ALL
`define DUMP_ALL 0
`endif

//initial begin
//    #2000
//    $finish;
//end

///////////////////
initial begin
    // dumpfile 
    if(`DUMP_FILE) begin
        $dumpfile(`VCD_PATH);
        if (`DUMP_ALL) $dumpvars(0,tb_spook_MSK);
        else $dumpvars(0,dut);
    end

    // TV files opening ////////
    //`define QUOTE(s) `"s`"
    infile = $fopen(`TV_PATH_IN,"r");
    outfile = $fopen(`TV_PATH_OUT,"w");

    if(infile==0) begin
        $display("ERROR: could not open infile.");
        $stop;
    end
    if(outfile==0) begin
        $display("ERROR: could not open outfile.");
        $stop;
    end

    // TB starts /////////////////
    clk = 0;
    rst = 1;
    com_bus_in_valid = 0;
    @(posedge clk); #0.01;
    @(posedge clk); #0.01;
    rst = 0;

    $display("RST done. Start simulation cases.");

    forever begin
        // Read ID=... or ##### line
        count_r = $fscanf(infile,"%s\n",read);
        end_file = (read[31:0]==endFile_string);
        if (end_file) begin
            $fwrite(outfile,"########\n");
            $finish;
        end
        $display("Starting new case (non-final), %d", $time);
        $fwrite(outfile,"%0d=ID\n",case_id_counter);
        case_id_counter = case_id_counter+1;
        received_ack = 0;

        // send TV to DUT
        nextdata_valid = 1;
        while (nextdata_valid) begin
            @(posedge clk); #0.01;
            while (~com_bus_in_ready) begin
                @(posedge clk); #0.01;
            end
            // read TV line
            count_r = $fscanf(infile,"%s\n",read);
            end_case = (read[8*8-1:0] == "--------");
            if (end_case) begin
                nextdata_valid = 0;
            end else begin
                counter_i = $sscanf(read,"%x%x%x%x",instruction);
                $display("new valid data, %d", $time);
                com_bus_in_valid = 1;
                @(posedge clk); #0.01;
                com_bus_in_valid = 0;
            end
        end
        while (received_ack != 5) begin
            @(posedge clk); #0.01;
        end
        $display("Run %0d done.",case_id_counter-1);
        $fwrite(outfile,"--------\n");
    end
end

always @(posedge clk) begin
    if (com_bus_out_valid) begin
        $fwrite(outfile,"%h%h%h%h\n",com_bus_out[31:24],com_bus_out[23:16],com_bus_out[15:8],com_bus_out[7:0]);
    end
    if (bus_out_last) begin
        received_ack = received_ack + 1;
    end
end


`ifdef physical_level
	initial begin
		$sdf_annotate(`SDF_ANNOTATE_FILE,dut);
	end
`endif


endmodule
