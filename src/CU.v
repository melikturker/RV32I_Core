`timescale 1ps / 1ps

module CU(operation, we_reg, we_mem, RF_sel, ALU_sel, op2_sel, is_load, is_signed, word_length, nop, rst);
	
	input [16:0] operation;
	input nop, rst;
		
	output reg we_reg, we_mem, is_load, is_signed;  
	output reg [1:0] op2_sel, word_length;
	output reg [2:0] RF_sel;
	output reg [3:0] ALU_sel;
	
	reg [9:0] cond_10bit;
	reg [10:0] cond_11bit;
	reg [6:0] opcode;

always @(*) begin

	opcode = operation[6:0];
	
	// Default values to prevent latches
	cond_10bit = 10'b0;
	cond_11bit = 11'b0;
	
	if (rst || nop) begin
		RF_sel = 3'b000;
		ALU_sel = 4'b0000;
		op2_sel = 2'b00;
		we_reg = 1'b0;
		we_mem = 1'b0;
		is_load = 1'b0;
		is_signed = 1'b1;
		word_length = 2'b10;
	end
	
	else begin
	
		if (opcode == 7'b0110011) begin // R type instructions

			cond_11bit = {operation[15], operation[9:7], opcode};
			
			is_load = 1'b0;
			word_length = 2'b10;
			
			case(cond_11bit)
						
				11'b00000110011: begin // ADD
					RF_sel = 3'b000;
					ALU_sel = 4'b0000;
					op2_sel = 2'b11;
					we_reg = 1'b1;
					we_mem = 1'b0;
					is_signed = 1'b1;
				end
				
				11'b10000110011: begin // SUB
					RF_sel = 3'b000;
					ALU_sel = 4'b0001;
					op2_sel = 2'b11;
					we_reg = 1'b1;
					we_mem = 1'b0;
					is_signed = 1'b1;
				end
				
				11'b00010110011: begin // SLL
					RF_sel = 3'b000;
					ALU_sel = 4'b0101;
					op2_sel = 2'b11;
					we_reg = 1'b1;
					we_mem = 1'b0;
					is_signed = 1'b1;
				end
				
				11'b00100110011: begin // SLT
					RF_sel = 3'b000;
					ALU_sel = 4'b1000;
					op2_sel = 2'b11;
					we_reg = 1'b1;
					we_mem = 1'b0;
					is_signed = 1'b1;
				end
				
				11'b00110110011: begin // SLTU
					RF_sel = 3'b000;
					ALU_sel = 4'b1001;
					op2_sel = 2'b11;
					we_reg = 1'b1;
					we_mem = 1'b0;
					is_signed = 1'b0;
				end
				
				11'b01000110011: begin // XOR 
					RF_sel = 3'b000;
					ALU_sel = 4'b0100;
					op2_sel = 2'b11;
					we_reg = 1'b1;
					we_mem = 1'b0;
					is_signed = 1'b1;
				end
				
				11'b01010110011: begin // SRL
					RF_sel = 3'b000;
					ALU_sel = 4'b0110;
					op2_sel = 2'b11;
					we_reg = 1'b1;
					we_mem = 1'b0;
					is_signed = 1'b1;
				end
				
				11'b11010110011: begin // SRA
					RF_sel = 3'b000;
					ALU_sel = 4'b0111;
					op2_sel = 2'b11;
					we_reg = 1'b1;
					we_mem = 1'b0;
					is_signed = 1'b1;
				end
				
				11'b01100110011: begin // OR
					RF_sel = 3'b000;
					ALU_sel = 4'b0011;
					op2_sel = 2'b11;
					we_reg = 1'b1;
					we_mem = 1'b0;
					is_signed = 1'b1;
				end
				
				11'b01110110011: begin // AND
					RF_sel = 3'b000;
					ALU_sel = 4'b0010;
					op2_sel = 2'b11;
					we_reg = 1'b1;
					we_mem = 1'b0;
					is_signed = 1'b1;
				end	
			endcase
		end
		
		else if (opcode == 7'b1100111 || opcode == 7'b0010011 || opcode == 7'b0000011) begin// I type instructions
			
			cond_10bit = {operation[9:7], opcode};
						
			case(cond_10bit) 
			
				10'b0010010011: begin // SLLI
					RF_sel = 3'b000;
					ALU_sel = 4'b0101;
					op2_sel = 2'b00;
					we_reg = 1'b1;
					we_mem = 1'b0;
					is_load = 1'b0;
					is_signed = 1'b1;
					word_length = 2'b10;
				end
				
				10'b1010010011: begin 
				
					if (operation[15] == 0) begin // SRLI
						RF_sel = 3'b000;
						ALU_sel = 4'b0110;
						op2_sel = 2'b00;
						we_reg = 1'b1;
						we_mem = 1'b0;
						is_load = 1'b0;
						is_signed = 1'b1;
						word_length = 2'b10;
					end
				
					else if (operation[15] == 1) begin	// SRAI
						RF_sel = 3'b000;
						ALU_sel = 4'b0111;
						op2_sel = 2'b00;
						we_reg = 1'b1;
						we_mem = 1'b0;
						is_load = 1'b0;
						is_signed = 1'b1;
						word_length = 2'b10;
					end
				end
			
				10'b0001100111: begin // JALR 
					RF_sel = 3'b011;
					ALU_sel = 4'b0000;
					op2_sel = 2'b00;
					we_reg = 1'b1;
					we_mem = 1'b0;
					is_load = 1'b0;
					is_signed = 1'b1;
					word_length = 2'b10;
				end
				
				10'b0000000011: begin // LB
					RF_sel = 3'b001;
					ALU_sel = 4'b0000;
					op2_sel = 2'b00;
					we_reg = 1'b1;
					we_mem = 1'b0;
					is_load = 1'b1;	
					is_signed = 1'b1;
					word_length = 2'b00;
				end
				
				10'b0010000011: begin // LH
					RF_sel = 3'b001;
					ALU_sel = 4'b0000;
					op2_sel = 2'b00;
					we_reg = 1'b1;
					we_mem = 1'b0;
					is_load = 1'b1;
					is_signed = 1'b1;
					word_length = 2'b01;
				end
				
				10'b0100000011: begin // LW
					RF_sel = 3'b001;
					ALU_sel = 4'b0000;
					op2_sel = 2'b00;
					we_reg = 1'b1;
					we_mem = 1'b0;
					is_load = 1'b1;
					is_signed = 1'b1;
					word_length = 2'b10;
				end
				
				10'b1000000011: begin // LBU
					RF_sel = 3'b001;
					ALU_sel = 4'b0000;
					op2_sel = 2'b00;
					we_reg = 1'b1;
					we_mem = 1'b0;
					is_load = 1'b1;
					is_signed = 1'b0;
					word_length = 2'b00;
				end
				
				10'b1010000011: begin // LHU
					RF_sel = 3'b001;
					ALU_sel = 4'b0000;
					op2_sel = 2'b00;
					we_reg = 1'b1;
					we_mem = 1'b0;
					is_load = 1'b1;
					is_signed = 1'b0;
					word_length = 2'b01;
				end
				
				10'b0000010011: begin // ADDI
					RF_sel = 3'b000;
					ALU_sel = 4'b0000;
					op2_sel = 2'b00;
					we_reg = 1'b1;
					we_mem = 1'b0;
					is_load = 1'b0;
					is_signed = 1'b1;
					word_length = 2'b10;
				end
			
				10'b0100010011: begin // SLTI
					RF_sel = 3'b000;
					ALU_sel = 4'b1000;
					op2_sel = 2'b00;
					we_reg = 1'b1;
					we_mem = 1'b0;
					is_load = 1'b0;
					is_signed = 1'b1;
					word_length = 2'b10;
				end
				
				10'b0110010011: begin // SLTIU
					RF_sel = 3'b000;
					ALU_sel = 4'b1001;
					op2_sel = 2'b00;
					we_reg = 1'b1;
					we_mem = 1'b0;
					is_load = 1'b0;
					is_signed = 1'b0;
					word_length = 2'b10;
				end
					
				10'b1000010011: begin // XORI
					RF_sel = 3'b000;
					ALU_sel = 4'b0100;
					op2_sel = 2'b00;
					we_reg = 1'b1;
					we_mem = 1'b0;
					is_load = 1'b0;
					is_signed = 1'b1;
					word_length = 2'b10;
				end
				
				10'b1100010011: begin // ORI
					RF_sel = 3'b000;
					ALU_sel = 4'b0011;
					op2_sel = 2'b00;
					we_reg = 1'b1;
					we_mem = 1'b0;
					is_load = 1'b0;
					is_signed = 1'b1;
					word_length = 2'b10;
				end
				
				10'b1110010011: begin // ANDI
					RF_sel = 3'b000;
					ALU_sel = 4'b0010;
					op2_sel = 2'b00;
					we_reg = 1'b1;
					we_mem = 1'b0;
					is_load = 1'b0;
					is_signed = 1'b1;
					word_length = 2'b10;
				end
				
			endcase
		end
		
		
		else if (opcode == 7'b0100011) begin // S type instructions
			
			cond_10bit = {operation[9:7], opcode};
			
			is_load = 1'b0;
			is_signed = 1'b1;
			
			case(cond_10bit)
			
				10'b0000100011: begin // SB
					RF_sel = 3'b000;
					ALU_sel = 4'b0000;
					op2_sel = 2'b01;
					we_reg = 1'b0;
					we_mem = 1'b1;
					word_length = 2'b00;
				end
				
				10'b0010100011: begin // SH
					RF_sel = 3'b000;
					ALU_sel = 4'b0000;
					op2_sel = 2'b01;
					we_reg = 1'b0;
					we_mem = 1'b1;
					word_length = 2'b01;
				end
				
				10'b0100100011: begin // SW
					RF_sel = 3'b000;
					ALU_sel = 4'b0000;
					op2_sel = 2'b01;
					we_reg = 1'b0;
					we_mem = 1'b1;
					word_length = 2'b10;
				end
			endcase
		end
		
		
		else if (opcode == 7'b1100011) begin // B type instructions
			
			cond_10bit = {operation[9:7], opcode};
						
			is_load = 1'b0;
			word_length = 2'b10;
			
			case(cond_10bit) 
				10'b0001100011: begin // BEQ 
					RF_sel = 3'b000;
					ALU_sel = 4'b0001;
					op2_sel = 2'b11;
					we_reg = 1'b0;
					we_mem = 1'b0;
					is_signed = 1'b1;
				end
		
				10'b0011100011: begin // BNE
					RF_sel = 3'b000;
					ALU_sel = 4'b0001;
					op2_sel = 2'b11;
					we_reg = 1'b0;
					we_mem = 1'b0;
					is_signed = 1'b1;
				end
				
				10'b1001100011: begin // BLT
					RF_sel = 3'b000;
					ALU_sel = 4'b0001;
					op2_sel = 2'b11;
					we_reg = 1'b0;
					we_mem = 1'b0;
					is_signed = 1'b1;
				end
			
				10'b1011100011: begin // BGE
					RF_sel = 3'b000;
					ALU_sel = 4'b0001;
					op2_sel = 2'b11;
					we_reg = 1'b0;
					we_mem = 1'b0;
					is_signed = 1'b1;
				end		
				
				
				10'b1101100011: begin // BLTU
					RF_sel = 3'b000;
					ALU_sel = 4'b0001;
					op2_sel = 2'b11;
					we_reg = 1'b0;
					we_mem = 1'b0;
					is_signed = 1'b0;
				end
			
				10'b1111100011: begin // BGEU
					RF_sel = 3'b000;
					ALU_sel = 4'b0001;
					op2_sel = 2'b11;
					we_reg = 1'b0;
					we_mem = 1'b0;
					is_signed = 1'b0;
				end		
			endcase
		end
		

		else if (opcode == 7'b0110111 || opcode == 7'b0010111) begin // U type instructions
			
			word_length = 2'b10;
			is_signed = 1'b1;
			
			case(opcode) 
				7'b0110111: begin // LUI 
					RF_sel = 3'b010;
					ALU_sel = 4'b0000;
					op2_sel = 2'b00; 
					we_reg = 1'b1;
					we_mem = 1'b0;
					is_load = 1'b0; // An exception
				end
				
				7'b0010111: begin // AUIPC 
					RF_sel = 3'b100;
					ALU_sel = 4'b0000;
					op2_sel = 2'b00;
					we_reg = 1'b1;
					we_mem = 1'b0;
					is_load = 1'b0;
				end			
			endcase
		end
		
		else if (opcode == 7'b1101111) begin // J type instructions
			RF_sel = 3'b011;
			ALU_sel = 4'b0000;
			op2_sel = 2'b10;
			we_reg = 1'b1;
			we_mem = 1'b0;
			is_load = 1'b0;
			word_length = 2'b10;
			is_signed = 1'b1;
		end
	
	    else if (opcode == 7'b1110011) begin // SYSTEM (ECALL, EBREAK) - Treated as NOP
			// ECALL and EBREAK are used for OS traps and debugging.
			// In this simple core, we treat them as NOPs to avoid crashing.
			RF_sel = 3'b000;
			ALU_sel = 4'b0000;
			op2_sel = 2'b00;
			we_reg = 1'b0;
			we_mem = 1'b0;
			is_load = 1'b0;
			is_signed = 1'b0;
			word_length = 2'b00;
		end

		else if (opcode == 7'b0001111) begin // FENCE - Treated as NOP
			// FENCE is used for memory ordering in multi-core systems.
			// Since this is a single-cycle-like ordered pipeline, explicit fencing is not needed logic-wise.
			RF_sel = 3'b000;
			ALU_sel = 4'b0000;
			op2_sel = 2'b00;
			we_reg = 1'b0;
			we_mem = 1'b0;
			is_load = 1'b0;
			is_signed = 1'b0;
			word_length = 2'b00;
		end
		else begin // Default (Unknown Opcode or Bubble not flagged by nop)
			RF_sel = 3'b000;
			ALU_sel = 4'b0000;
			op2_sel = 2'b00;
			we_reg = 1'b0;
			we_mem = 1'b0;
			is_load = 1'b0;
			is_signed = 1'b1;
			word_length = 2'b10;
		end
		end
	end
endmodule 