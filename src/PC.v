`timescale 1ps / 1ps

module PC(sel, clk, rst, B_imm, J_imm, ALU_out, PC_out); // Program counter
	
	input clk, rst;
	input [1:0] sel;
	input [31:0] B_imm, J_imm, ALU_out;
	output reg [31:0] PC_out;
	
	always @(posedge clk) begin
		
		if(rst) PC_out = 31'b0;
		else begin 
			case(sel)
				2'b00: PC_out = PC_out + 4;
				2'b01: PC_out = PC_out + B_imm;
				2'b10: PC_out = PC_out + J_imm;
				2'b11: PC_out = ALU_out;
			endcase
		end
	end
endmodule 