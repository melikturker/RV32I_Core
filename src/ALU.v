`timescale 1ns / 1ps

module ALU (op1, op2, sel, is_signed, result, Z, N);

	input [31:0] op1, op2;
	input [2:0] sel;
	input is_signed;
	
	output reg [31:0] result;
	output reg Z, N;
	
	reg [32:0] result_ext;
	
	always@(*) begin
	
	if (!is_signed) begin
			case (sel)	
				3'b000: result_ext = op1 + op2; // ADD 
				3'b001: result_ext = op1 - op2; // SUB	
				default: result_ext = 33'b0;
			endcase
			result = result_ext[31:0];
	end
	if (is_signed) begin
			case (sel)	
				3'b000: result = op1 + op2; // ADD 
				3'b001: result = op1 - op2; // SUB
				3'b010: result = op1 & op2; // AND
				3'b011: result = op1 | op2; // OR
				3'b100: result = op1 ^ op2; // XOR
				3'b101: result = op1 << op2[4:0]; // Shift Left Logical
				3'b110: result = op1 >> op2[4:0]; // Shift Right Logical			
				3'b111: result = $signed(op1) >>> op2[4:0] ; //Shift Right Arithmetical
			endcase
	end
	
	if (result == 0) Z = 1'b1;
	else Z = 1'b0;
	 
	if ((is_signed & result[31]) | (!is_signed & result_ext[32])) N = 1'b1; 
	else N = 1'b0;

	
	
	end




endmodule
