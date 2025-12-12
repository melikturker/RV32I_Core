`timescale 1ps / 1ps

module I_mem (instruction, address, we, nop_in, nop_out, rst, clk);

input we, nop_in, rst, clk;
input	[31:0] address;
output reg [31:0]	instruction;
output reg nop_out;

//	memAddr is an address register in the memory side.
reg	[31:0]	memAddr;
reg	[31:0]	Imem[0:2047];

	//	The I-Memory is initially loaded
    reg [1023:0] test_file_path;
initial begin
    if ($value$plusargs("TESTFILE=%s", test_file_path)) begin
        $readmemh(test_file_path, Imem);
    end else begin
        $readmemh("instructions/instr.txt", Imem);
    end
end

always @(posedge clk) begin
	
	nop_out = nop_in;
	if(!rst && we && !nop_in) begin
		memAddr = address/4;
		instruction = Imem[memAddr];
	end
	
	else if (nop_in) begin 
		instruction = 32'h00000013;   // nop instruction. 
	end
end

endmodule 