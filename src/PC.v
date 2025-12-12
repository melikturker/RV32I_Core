`timescale 1ps / 1ps

module PC(sel, clk, rst, we, rev, PC_4, PC_out); // Program counter
	
	input clk, rst, we, rev;
	input [1:0] sel; // Unused if PC_in logic is external, but keeping to match port order
	input [31:0] PC_4; // This is mapped to PC_in in Core.v
	output reg [31:0] PC_out;
	
	always @(posedge clk) begin
		
		if(rst) PC_out <= 32'b0;
		else begin 
			if (rev) PC_out <= PC_out - 4;
			else if (we) PC_out <= PC_4;
			else PC_out <= PC_out;
		end
	end
endmodule