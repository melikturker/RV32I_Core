`timescale 1ns / 1ps

module ALU (op1, op2, sel, is_signed, result, Z, N);

	input [31:0] op1, op2;
	input [3:0] sel;
	input is_signed;
	
	output reg [31:0] result;
	output reg Z, N;
	
	wire signed [31:0] op1_s = op1;
	wire signed [31:0] op2_s = op2;
	
	always@(*) begin
		
		result = 32'b0; // Default value
		Z = 0;
		N = 0;

		case (sel)	
			4'b0000: result = op1 + op2; // ADD 
			4'b0001: result = op1 - op2; // SUB
			4'b0010: result = op1 & op2; // AND
			4'b0011: result = op1 | op2; // OR
			4'b0100: result = op1 ^ op2; // XOR
			4'b0101: result = op1 << op2[4:0]; // SLL (Logical Left Shift)
			4'b0110: result = op1 >> op2[4:0]; // SRL (Logical Right Shift)
			4'b0111: result = op1_s >>> op2[4:0]; // SRA (Arithmetic Right Shift)
			4'b1000: result = (op1_s < op2_s) ? 32'b1 : 32'b0; // SLT
			4'b1001: result = (op1 < op2) ? 32'b1 : 32'b0; // SLTU
			default: result = 32'b0;
		endcase
		
		// Z Flag Logic
		if (result == 0) Z = 1'b1;
		else Z = 1'b0;
		
		// N Flag Logic
		if (sel == 4'b0001) begin // SUB (Branch comparison)
 			if (is_signed) begin
				if (op1_s < op2_s) N = 1'b1;
				else N = 1'b0;
			end else begin
				if (op1 < op2) N = 1'b1;
				else N = 1'b0;
			end
		end else begin
			N = result[31];
		end
	end




endmodule
