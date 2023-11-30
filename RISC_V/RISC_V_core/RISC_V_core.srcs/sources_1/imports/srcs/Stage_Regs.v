
module IF_ID(PC_in, PC_4_in, nop, nop_out, 
				 PC_out, PC_4_out, we, we_out, rst, clk);

	input [31:0] PC_in, PC_4_in;
	input rst, clk, nop, we;
	output reg [31:0] PC_out, PC_4_out;
	output reg we_out, nop_out;
	
	always @(posedge clk) begin
	
		we_out = we;
		nop_out = nop;
		
		if (!rst && we && !nop) begin // Nop can be unnecessary
			PC_out = PC_in;
			PC_4_out = PC_4_in;
		end
		
		else if(nop) begin
			PC_out = 32'b0;
			PC_4_out = 32'b0;
		end
		
		else begin
			PC_out = PC_out;
			PC_4_out = PC_4_out;
		end
	end
	
endmodule

module ID_EX(PC_in, PC_4_in, imm_I_in, imm_S_in, imm_B_in, imm_U_in, imm_J_in, opcode_in, funct3_in,
				 rs1_in, rs2_in, rd_in, ALU_sel_in, op2_sel_in, RF_sel_in, we_mem_in, we_reg_in, is_load_in, is_signed_in, word_length_in,
				
				 PC_out, PC_4_out, imm_I_out, imm_S_out, imm_B_out, imm_U_out, imm_J_out, opcode_out, funct3_out,
				 rs1_out, rs2_out, rd_out, ALU_sel_out, op2_sel_out, RF_sel_out, we_mem_out, we_reg_out, is_load_out, is_signed_out, word_length_out, nop, we, clk);
				 
				input [31:0] PC_in, PC_4_in, imm_I_in, imm_S_in, imm_B_in, imm_U_in, imm_J_in;
				input [4:0] rd_in, rs1_in, rs2_in;
				input [2:0] ALU_sel_in;
				input [1:0] op2_sel_in;
				input [2:0] RF_sel_in, funct3_in;
				input [6:0] opcode_in;
				input [1:0] word_length_in;
				input we_mem_in, we_reg_in, is_load_in, is_signed_in, nop, we, clk;
				
				
				output reg [31:0] PC_out, PC_4_out, imm_I_out, imm_S_out, imm_B_out, imm_U_out, imm_J_out;
				output reg [4:0] rd_out, rs1_out, rs2_out;
				output reg [2:0] ALU_sel_out;
				output reg [1:0] op2_sel_out;
				output reg [2:0] RF_sel_out, funct3_out;
				output reg [6:0] opcode_out;
				output reg [1:0] word_length_out;
				output reg we_mem_out, is_load_out, is_signed_out, we_reg_out;
				 
				 
			always @(posedge clk) begin
				if(we) begin
					PC_out = PC_in; 
					PC_4_out = PC_4_in; 
					imm_I_out = imm_I_in; 
					imm_S_out = imm_S_in; 
					imm_B_out = imm_B_in; 
					imm_U_out = imm_U_in; 
					imm_J_out = imm_J_in;
					opcode_out = opcode_in;
					funct3_out = funct3_in;
					rs1_out = rs1_in;
					rs2_out = rs2_in;
					rd_out = rd_in;
					ALU_sel_out = ALU_sel_in; 
					op2_sel_out = op2_sel_in;
					RF_sel_out = RF_sel_in;
					is_signed_out = is_signed_in;
					word_length_out = word_length_in;
					
					
					if (!nop) begin
						we_mem_out = we_mem_in;
						we_reg_out = we_reg_in;
						is_load_out = is_load_in;
					end
					else begin
						we_mem_out = 1'b0;
						we_reg_out = 1'b0;
						is_load_out = 1'b0;
						PC_out = 32'b0;
						PC_4_out = 32'b0;
					end
				end
				else begin
					PC_out = PC_out; 
					PC_4_out = PC_4_out; 
					imm_I_out = imm_I_out; 
					imm_S_out = imm_S_out; 
					imm_B_out = imm_B_out; 
					imm_U_out = imm_U_out; 
					imm_J_out = imm_J_out; 
					rd_out = rd_out;
					ALU_sel_out = ALU_sel_out; 
					op2_sel_out = op2_sel_out;
					RF_sel_out = RF_sel_out;
					we_mem_out = we_mem_out;
					we_reg_out = we_reg_out;
					is_load_out = is_load_out;
				end
			end		 
endmodule 

module EX_MEM(PC_in, PC_4_in, ALU_result_in, imm_U_in, rd_in, we_reg_in, we_mem_in, RF_sel_in, datain_in, is_load_in, is_signed_in, word_length_in,
				  PC_out, PC_4_out, ALU_result_out, imm_U_out, rd_out, we_reg_out, we_mem_out, RF_sel_out, datain_out, is_load_out, is_signed_out, word_length_out, nop, clk, rst);
		
				input [31:0] PC_in, PC_4_in, ALU_result_in, imm_U_in, datain_in;
				input [4:0] rd_in;
				input [2:0] RF_sel_in;
				input [1:0] word_length_in;
				input is_load_in, is_signed_in, we_reg_in, we_mem_in, nop, clk, rst;
				
				
				output reg [31:0] PC_out, PC_4_out, ALU_result_out, imm_U_out, datain_out;
				output reg [4:0] rd_out;
				output reg [2:0] RF_sel_out;
				output reg [1:0] word_length_out;
				output reg is_load_out, is_signed_out, we_reg_out, we_mem_out;
				
		
			always @(posedge clk) begin
				PC_out = PC_in;
				PC_4_out = PC_4_in;
				ALU_result_out = ALU_result_in;
				imm_U_out = imm_U_in;
				rd_out = rd_in;
				RF_sel_out = RF_sel_in;
				datain_out = datain_in;
				is_signed_out = is_signed_in;
				word_length_out = word_length_in;
				
				if (!nop) begin
					we_reg_out = we_reg_in;
					we_mem_out = we_mem_in;
					is_load_out = is_load_in;
				end
				
				else begin
					we_reg_out = 1'b0;
					we_mem_out = 1'b0;
					is_load_out = 1'b0;
				end
			end 
endmodule 

module MEM_WB(PC_in, PC_4_in, ALU_result_in, imm_U_in, rd_in, we_reg_in, RF_sel_in, is_signed_in, word_length_in,
				  PC_out, PC_4_out, ALU_result_out, imm_U_out, rd_out, we_reg_out, RF_sel_out, is_signed_out, word_length_out, clk, rst);
				  
					input [31:0] PC_in, PC_4_in, ALU_result_in, imm_U_in;
					input [4:0] rd_in;
					input [2:0] RF_sel_in;
					input [1:0] word_length_in;
					input we_reg_in, is_signed_in, clk, rst;
					
					
					output reg [31:0]  PC_out, PC_4_out, ALU_result_out, imm_U_out;
					output reg [4:0] rd_out;
					output reg [2:0] RF_sel_out;
					output reg [1:0] word_length_out;
					output reg we_reg_out, is_signed_out;
					
					always @(posedge clk) begin
						PC_out = PC_in;
						PC_4_out = PC_4_in;
						ALU_result_out = ALU_result_in;
						imm_U_out = imm_U_in;
						rd_out = rd_in;
						RF_sel_out = RF_sel_in;
						we_reg_out = we_reg_in;	
						is_signed_out = is_signed_in;
						word_length_out = word_length_in;
					end
endmodule 