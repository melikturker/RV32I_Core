`timescale 1ps / 1ps

module I_mem (instruction, address, we, nop_in, nop_out, rst, clk);

input we, nop_in, rst, clk;
input	[31:0] address;
output reg [31:0]	instruction;
output reg nop_out;

//	memAddr is an address register in the memory side.
reg	[31:0]	memAddr;
reg	[31:0]	Imem[0:511];

	//	The I-Memory is initially loaded
initial
	$readmemh ("instructions/instr.txt", Imem);

	//	I-mem is read in every cycle.
	//	A read signal could be added if neccessary.
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