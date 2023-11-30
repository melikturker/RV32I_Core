`timescale 1ns / 1ps

module Core (clk, rst);

	input clk, rst;	
	
	wire [31:0] PC_IF, PC_ID, PC_EX, PC_MEM, PC_WB; 					// PC propagation through stages
	wire [31:0] PC_4_IF, PC_4_ID, PC_4_EX, PC_4_MEM, PC_4_WB; 		// PC + 4 propagation through stages
	wire [1:0] PC_sel;
	
	wire [1:0] op2_sel_ID, op2_sel_EX;
	wire [2:0] ALU_sel_ID, ALU_sel_EX;
	wire [2:0] RF_sel_ID, RF_sel_EX1, RF_sel_EX2, RF_sel_MEM, RF_sel_WB;
	wire Z, N;
	
	wire rev_PC, we_PC; 
	wire we_reg_ID, we_reg_EX, we_reg_MEM, we_reg_WB; 
	wire we_mem_ID, we_mem_EX, we_mem_MEM;
	
	reg [31:0] op1, op2; 	// Second operand of ALU, first one is directly connected to the reg_out1
	reg [31:0] RF_in; 		// Input for RF
	reg [31:0] PC_in; 		// Program Counter input
	
	wire is_load_ID, is_load_EX, is_load_MEM; 	// Determines the instruction is load or not. Used by Forwarding Unit
	wire FU_sel1, FU_sel2; 								// Sellect signals for output of Forwarding Unit
	wire [31:0] FU_out1, FU_out2; 					// Outputs of forwarding unit
	
	
	wire is_signed_ID, is_signed_EX, is_signed_MEM, is_signed_WB; 							// Determines the instruction is signed or unsigned.
	wire [1:0] word_length_ID, word_length_EX, word_length_MEM, word_length_WB; 		// Determines the word lenght such as byte, half word or word. 
	wire [31:0] SLU_out, LLU_out; 																	// Outputs of Store Length Unit and Load Length Unit
	wire [1:0] byte_mask;																				// Determines which bytes of the word will be placed in the memory.
	
	wire we_ID, we_ID2, we_EX, nop_CU, nop_ID, nop_ID2, nop_EX, nop_MEM;
	wire stall_FU, flush;
	reg [31:0] rs2_sel; 																						// This wire is connected to the output of MUX that sellects FU_out2 and reg_out2.
		
	wire [11:0] I_imm_in, S_imm_in, B_imm_in; 														// Immediate values extracted from instruction
	wire [31:0] I_imm_out, S_imm_out, B_imm_out, U_imm_out, J_imm_out; 						// Extended immediate values which is output of imm_units
	wire [31:0] I_imm_EX, S_imm_EX, B_imm_EX, U_imm_EX, U_imm_MEM, U_imm_WB, J_imm_EX; 	// Propagated immediate values
	wire [31:0] ALU_out_EX, ALU_out_MEM, ALU_out_WB ; 												// Output of ALU
	wire [31:0] instr; 																						// 32-bit instruction
	wire [4:0]  rs1, rs2, rs1_EX, rs2_EX; 																// 5-bit source register addresses
	wire [4:0]  rd_ID, rd_EX, rd_MEM, rd_WB;
	wire [19:0] U_imm_in, J_imm_in;
	wire [16:0] CU_info; 																					// Decoder notifies the instruction to CU 
	wire [6:0] opcode_EX;
	wire [2:0] func3_EX;
	wire [31:0] reg_out1_EX, reg_out2_EX, reg_out2_MEM; 											// Outputs of RF
	wire [31:0] D_mem_out; 																					// Output and input of D_mem. D_mem_in is not used, since it is directly connected to reg_out2.
	
	wire ready;																									// Ready signal of D-MEM to inform data cache.
	
	always @(*) begin
		
		if(!rst) begin
					
			case(PC_sel)
				2'b00: PC_in = PC_IF + 4;
				2'b01: PC_in = PC_EX + B_imm_EX;
				2'b10: PC_in = PC_EX + J_imm_EX;
				2'b11: PC_in = ALU_out_EX;
			endcase
			
			case (FU_sel1)
				1'b0: op1 = reg_out1_EX;
				1'b1: op1 = FU_out1;
			endcase
			
			case (FU_sel2)
				1'b0: rs2_sel = reg_out2_EX;
				1'b1: rs2_sel = FU_out2;
			endcase
		
			case (op2_sel_EX)
				2'b00: op2 = I_imm_EX;
				2'b01: op2 = S_imm_EX;
				2'b10: op2 = J_imm_EX;
				2'b11: op2 = rs2_sel;
			endcase
			
			case (RF_sel_WB)
				3'b000: RF_in = ALU_out_WB;
				3'b001: RF_in = LLU_out; //D_mem_out; 
				3'b010: RF_in = U_imm_WB;
				3'b011: RF_in = PC_WB + 4;
				3'b100: RF_in = PC_WB + U_imm_WB; // It can be done with ALU but it makes size of the mux larger.
				3'b101: RF_in = 32'h0;
				3'b110: RF_in = 32'h1;
				3'b111: RF_in = 32'h0;
			endcase
		end
	end
	
	// ------------ Stall Unit ------------
	
	Stall_Unit SU(nop_ID, nop_EX, nop_MEM, we_ID, we_EX, rev_PC, we_PC, stall_FU, flush, rst); 
	
	// ------------ Forwarding Unit ------------	
	Forwarding_Unit FU(ALU_out_EX, ALU_out_MEM, RF_in, PC_EX, PC_MEM, PC_4_EX, PC_4_MEM, U_imm_EX, U_imm_MEM, U_imm_WB,
								rd_EX, rd_MEM, rd_WB, rs1_EX, rs2_EX,
								RF_sel_MEM, we_reg_MEM, we_reg_WB,
								FU_out1, FU_out2, FU_sel1, FU_sel2,
								is_load_MEM, stall_FU, rst);
	
	PC_sel_Unit PCU(opcode_EX, func3_EX, nop_ID2, Z, N, RF_sel_EX1, flush, RF_sel_EX2, PC_sel, rst);
	
	//module PC_sel_Unit(opcode, funct3, Z, N, RF_sel_in, flush, RF_sel_out, PC_sel, rst);
	
	
	// ------------ IF stage ------------
	PC PC(PC_sel, clk, rst, we_PC, rev_PC, PC_in, PC_IF); 
	
	I_mem I_mem(instr, PC_IF, we_ID, nop_ID, nop_CU, rst, clk);
	
	IF_ID IF_ID(PC_IF, PC_4_IF, nop_ID, nop_ID2, PC_ID, PC_4_ID, we_ID, we_ID2, rst, clk); // IF to ID stage register 
	// ------------ ID stage ------------
	
	
	Decode Decoder(instr, rs1, rs2, rd_ID, I_imm_in, S_imm_in, B_imm_in, U_imm_in, J_imm_in,  CU_info);
	
	imm_I  imm_I(I_imm_in, I_imm_out);
	imm_S  imm_S(S_imm_in, S_imm_out);
	imm_B  imm_B(B_imm_in, B_imm_out);
	imm_U  imm_U(U_imm_in, U_imm_out);
	imm_J  imm_J(J_imm_in, J_imm_out);
	
	CU CU(CU_info, we_reg_ID, we_mem_ID, RF_sel_ID, ALU_sel_ID, op2_sel_ID, is_load_ID, is_signed_ID, word_length_ID, nop_CU, rst);
	
	RF regFile(rs1, rs2, rd_WB, RF_in, reg_out1_EX, reg_out2_EX, we_reg_WB, clk);

	
	ID_EX ID_EX(PC_ID, PC_4_ID, I_imm_out, S_imm_out, B_imm_out, U_imm_out, J_imm_out,  CU_info[6:0], CU_info[9:7],
			rs1, rs2, rd_ID, ALU_sel_ID, op2_sel_ID, RF_sel_ID, we_mem_ID, we_reg_ID, is_load_ID, is_signed_ID, word_length_ID,
			
			PC_EX, PC_4_EX, I_imm_EX, S_imm_EX, B_imm_EX, U_imm_EX, J_imm_EX, opcode_EX, func3_EX,
			rs1_EX, rs2_EX, rd_EX, ALU_sel_EX, op2_sel_EX, RF_sel_EX1, we_mem_EX, we_reg_EX, is_load_EX, is_signed_EX, word_length_EX, nop_EX, we_EX, clk);

	// ------------ EX stage ------------

	
	ALU ALU(op1, op2, ALU_sel_EX, is_signed_EX, ALU_out_EX, Z, N);
	
	EX_MEM EX_MEM(PC_EX, PC_4_EX, ALU_out_EX, U_imm_EX, rd_EX, we_reg_EX, we_mem_EX, RF_sel_EX2, rs2_sel, is_load_EX, is_signed_EX, word_length_EX,
					  PC_MEM, PC_4_MEM, ALU_out_MEM, U_imm_MEM, rd_MEM, we_reg_MEM, we_mem_MEM, RF_sel_MEM, reg_out2_MEM, is_load_MEM, is_signed_MEM, word_length_MEM, nop_MEM, clk, rst);
	
	// ------------ MEM stage ------------
	
	Store_Length_Unit SLU(reg_out2_MEM, word_length_MEM, byte_mask, SLU_out); // wire byte_mask will be replaced with word length signal. maybe word_length2
	
	
	D_mem D_mem(ALU_out_MEM, reg_out2_MEM, D_mem_out, we_mem_MEM, clk); // wire byte_mask will be replaced with word length signal. maybe word_length2
	
	MEM_WB MEM_WB(PC_MEM, PC_4_MEM, ALU_out_MEM, U_imm_MEM, rd_MEM, we_reg_MEM, RF_sel_MEM, is_signed_MEM, word_length_MEM,
					  PC_WB, PC_4_WB, ALU_out_WB, U_imm_WB, rd_WB, we_reg_WB, RF_sel_WB, is_signed_WB, word_length_WB, clk, rst);
	
	// ------------ WB stage ------------
	
	Load_Length_Unit LLU(D_mem_out, word_length_WB, is_signed_WB, LLU_out);

endmodule 