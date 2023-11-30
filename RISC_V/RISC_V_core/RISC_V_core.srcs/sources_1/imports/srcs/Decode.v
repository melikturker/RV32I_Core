`timescale 1ns / 1ps

module Decode(inst, rs1, rs2, rd, imm_I, imm_S, imm_B, imm_U, imm_J,  CU_info);

input [31:0] inst;
output reg [4:0] rs1, rs2, rd;
output reg [11:0]imm_I;
output reg [11:0]imm_S;
output reg [11:0]imm_B;
output reg [19:0]imm_U;
output reg [19:0]imm_J;
output reg [16:0]CU_info;


reg [6:0] opcode;
reg [2:0] funct3;
reg [6:0] funct7;


always @(*) begin

opcode = inst[6:0];

case(opcode)

	7'b0110011: begin // R type instruction
	
	 rd = inst[11:7];
	 funct3 = inst[14:12];
	 rs1 = inst[19:15];
	 rs2 = inst[24:20];
	 funct7 = inst[31:25];
	 CU_info = {funct7, funct3, opcode};
	end


	7'b1100111: begin // I type instruction
	 rd = inst[11:7];
	 funct3 = inst[14:12];
	 rs1 = inst[19:15];
	 imm_I = inst[31:20]; 
	 CU_info = {7'b0, funct3, opcode};
	end
	
	7'b0010011: begin // I type instruction 
	 rd = inst[11:7];
	 funct3 = inst[14:12];
	 rs1 = inst[19:15];
	 imm_I = inst[31:20]; 
	 CU_info = {{inst[31:25] & 7'b0100000}, funct3, opcode};
	end
	
	7'b0000011: begin // I type instruction
	 rd = inst[11:7];
	 funct3 = inst[14:12];
	 rs1 = inst[19:15];
	 imm_I = inst[31:20]; 
	 CU_info = {7'b0, funct3, opcode};
	end
	

	7'b0100011: begin // S type instruction
	
	 imm_S = {inst[31:25], inst[11:7]};
	 funct3 = inst[14:12];
	 rs1 = inst[19:15];
	 rs2 = inst[24:20];
	 CU_info = {7'b0, funct3, opcode};
	end
	
	7'b1100011: begin // B type instruction
	
	 imm_B = {inst[31:25], inst[11:7]};
	 funct3 = inst[14:12];
	 rs1 = inst[19:15];
	 rs2 = inst[24:20];
	 CU_info = {7'b0, funct3, opcode};
	
	end

	7'b0110111: begin // U type instruction
	 
	 rd = inst[11:7];
	 imm_U = inst[31:12];
	 CU_info = {10'b0, opcode};
	 
	end
	
	7'b0010111: begin // U type instruction
	 
	 rd = inst[11:7];
	 imm_U = inst[31:12];
	 CU_info = {10'b0, opcode};
	
	end

	7'b1101111: begin // J type instruction
	
	 rd = inst[11:7];
	 imm_J= inst[31:12];
	 CU_info = {10'b0, opcode};
	 
	end

endcase

end

endmodule 