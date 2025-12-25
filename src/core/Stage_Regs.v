
module IF_ID(PC_in, PC_4_in, instr_in, nop, nop_out, 
				 PC_out, PC_4_out, instr_out, we, we_out, rst, clk);

	input [31:0] PC_in, PC_4_in, instr_in;
	input rst, clk, nop, we;
	output reg [31:0] PC_out, PC_4_out, instr_out;
	output reg we_out, nop_out;
	
	always @(posedge clk) begin
	   if (rst) begin
	       // Reset Condition
	       we_out <= 1'b1; 
	       nop_out <= 1'b0;
	       PC_out <= 32'b0;
	       PC_4_out <= 32'b0;
           instr_out <= 32'h00000013; // Reset to NOP
	   end
	   else begin
		we_out <= we;
		nop_out <= nop;
		
		if (we && !nop) begin 
			PC_out <= PC_in;
			PC_4_out <= PC_4_in;
            instr_out <= instr_in;
		end
		
		else if(nop) begin
			PC_out <= 32'b0;
			PC_4_out <= 32'b0;
            instr_out <= 32'h00000013; // Flush to NOP
		end
		
		else begin // Hold
			PC_out <= PC_out;
			PC_4_out <= PC_4_out;
            instr_out <= instr_out;
		end
	end
	end
	
endmodule

module ID_EX(PC_in, PC_4_in, imm_I_in, imm_S_in, imm_B_in, imm_U_in, imm_J_in, opcode_in, funct3_in,
				 rs1_in, rs2_in, rd_in, ALU_sel_in, op2_sel_in, RF_sel_in, we_mem_in, we_reg_in, is_load_in, is_signed_in, word_length_in,
				
				 PC_out, PC_4_out, imm_I_out, imm_S_out, imm_B_out, imm_U_out, imm_J_out, opcode_out, funct3_out,
				 rs1_out, rs2_out, rd_out, ALU_sel_out, op2_sel_out, RF_sel_out, we_mem_out, we_reg_out, is_load_out, is_signed_out, word_length_out, nop_out, nop, we, clk, rst);
				 
				input [31:0] PC_in, PC_4_in, imm_I_in, imm_S_in, imm_B_in, imm_U_in, imm_J_in;
				input [4:0] rd_in, rs1_in, rs2_in;
				input [3:0] ALU_sel_in;
				input [1:0] op2_sel_in;
				input [2:0] RF_sel_in, funct3_in;
				input [6:0] opcode_in;
				input [1:0] word_length_in;
				input we_mem_in, we_reg_in, is_load_in, is_signed_in, nop, we, clk, rst;
				
				
				output reg [31:0] PC_out, PC_4_out, imm_I_out, imm_S_out, imm_B_out, imm_U_out, imm_J_out;
				output reg [4:0] rd_out, rs1_out, rs2_out;
				output reg [3:0] ALU_sel_out;
				output reg [1:0] op2_sel_out;
				output reg [2:0] RF_sel_out, funct3_out;
				output reg [6:0] opcode_out;
				output reg [1:0] word_length_out;
				output reg we_mem_out, is_load_out, is_signed_out, we_reg_out, nop_out;
				 
				 
			always @(posedge clk) begin
				if (rst) begin
					PC_out <= 32'b0; 
					PC_4_out <= 32'b0; 
					imm_I_out <= 32'b0; 
					imm_S_out <= 32'b0; 
					imm_B_out <= 32'b0; 
					imm_U_out <= 32'b0; 
					imm_J_out <= 32'b0;
					opcode_out <= 7'b0;  // Reset opcode
					funct3_out <= 3'b0;
					rs1_out <= 5'b0;
					rs2_out <= 5'b0;
					rd_out <= 5'b0;
					ALU_sel_out <= 4'b0; 
					op2_sel_out <= 2'b0;
					RF_sel_out <= 3'b0;
					is_signed_out <= 1'b0;
					word_length_out <= 2'b0;
					we_mem_out <= 1'b0;
					we_reg_out <= 1'b0;
					is_load_out <= 1'b0;
                    nop_out <= 1'b0;
				end
				else if(we || nop) begin // Update if we OR nop (Bubble)
		// Opcode: Clear on NOP (flush), otherwise propagate
		opcode_out <= nop ? 7'b0 : opcode_in;
				
				if (we) begin
                    PC_out <= PC_in; 
                    PC_4_out <= PC_4_in; 
                    imm_I_out <= imm_I_in; 
                    imm_S_out <= imm_S_in; 
                    imm_B_out <= imm_B_in; 
                    imm_U_out <= imm_U_in; 
                    imm_J_out <= imm_J_in;
                    funct3_out <= funct3_in;
                    rs1_out <= rs1_in;
                    rs2_out <= rs2_in;
                    rd_out <= rd_in;
                    ALU_sel_out <= ALU_sel_in; 
                    op2_sel_out <= op2_sel_in;
                    RF_sel_out <= RF_sel_in;
                    is_signed_out <= is_signed_in;
                    word_length_out <= word_length_in;

                end
                // If nop, some of above might be overwritten or cleared below
                
                // Controls Logic (Ternary for robustness against NOP)
                // If NOP, force 0. Else if WE, take Input. Else Hold (Covered by outer if?)
                // Outer if is (we || nop). So if we=0 and nop=1, we enter.
                // If nop=1, force 0.
                we_mem_out <= nop ? 1'b0 : we_mem_in;
                we_reg_out <= nop ? 1'b0 : we_reg_in;
                is_load_out <= nop ? 1'b0 : is_load_in;
                
                // NOP Propagation: If nop input is 1, nop_out must be 1.
                // If nop is 0 and we is 1 (Valid), nop_out must be 0.
                nop_out <= nop ? 1'b1 : 1'b0;
                
                if (nop) begin
                    PC_out <= 32'b0; 
                    PC_4_out <= 32'b0;
                    rd_out <= 5'b0;
                    RF_sel_out <= 3'b0; // Explicitly clear RF_sel
                    ALU_sel_out <= 4'b0;
                    op2_sel_out <= 2'b0;
                    funct3_out <= 3'b0;
                end
				end
				else begin // Hold
					PC_out <= PC_out; 
					PC_4_out <= PC_4_out; 
                    // ... (Hold logic mostly implicit if not assigned, but explict here)
                    // ... (Reduced for brevity, Verilog allows implicit hold on Registers)
					imm_I_out <= imm_I_out; 
					imm_S_out <= imm_S_out; 
					imm_B_out <= imm_B_out; 
					imm_U_out <= imm_U_out; 
					imm_J_out <= imm_J_out; 
					rd_out <= rd_out;
					ALU_sel_out <= ALU_sel_out; 
					op2_sel_out <= op2_sel_out;
					RF_sel_out <= RF_sel_out;
					we_mem_out <= we_mem_out;
					we_reg_out <= we_reg_out;
					is_load_out <= is_load_out;
                    nop_out <= nop_out;
                    // ...
				end
                
                // Debug Post

			end
            
            // New logic for nop_out (Always latch incoming nop if WE or NOP active)
            // Wait, we can put it in main block
            // nop_out <= nop;
            // But main block has 'else if (we || nop)'.
            // if nop=1, nop_out=1. if we=1, nop_out=nop.
            // Simplified:
            // always @(posedge clk) if (we || nop) nop_out <= nop;
            // Let's integrate into main block.
            

endmodule 

module EX_MEM(PC_in, PC_4_in, ALU_result_in, imm_U_in, rd_in, we_reg_in, we_mem_in, RF_sel_in, datain_in, is_load_in, is_signed_in, word_length_in, opcode_in,
				  PC_out, PC_4_out, ALU_result_out, imm_U_out, rd_out, we_reg_out, we_mem_out, RF_sel_out, datain_out, is_load_out, is_signed_out, word_length_out, opcode_out, nop, clk, rst);
		
				input [31:0] PC_in, PC_4_in, ALU_result_in, imm_U_in, datain_in;
				input [4:0] rd_in;
				input [2:0] RF_sel_in;
				input [1:0] word_length_in;
				input [6:0] opcode_in;
				input is_load_in, is_signed_in, we_reg_in, we_mem_in, nop, clk, rst;
				
				
				output reg [31:0] PC_out, PC_4_out, ALU_result_out, imm_U_out, datain_out;
				output reg [4:0] rd_out;
				output reg [2:0] RF_sel_out;
				output reg [1:0] word_length_out;
				output reg [6:0] opcode_out;
				output reg is_load_out, is_signed_out, we_reg_out, we_mem_out;
				
		
			always @(posedge clk) begin
				if (rst) begin
					PC_out <= 32'b0;
					PC_4_out <= 32'b0;
					ALU_result_out <= 32'b0;
					imm_U_out <= 32'b0;
					rd_out <= 5'b0;
					RF_sel_out <= 3'b0;
					datain_out <= 32'b0;
					is_signed_out <= 1'b0;
					word_length_out <= 2'b0;
					opcode_out <= 7'b0;  // Reset opcode
					we_reg_out <= 1'b0;
					we_mem_out <= 1'b0;
					is_load_out <= 1'b0;
				end
				else begin
					PC_out <= PC_in;
					PC_4_out <= PC_4_in;
					ALU_result_out <= ALU_result_in;
					imm_U_out <= imm_U_in;
					rd_out <= rd_in;
					RF_sel_out <= RF_sel_in;
					datain_out <= datain_in;
					is_signed_out <= is_signed_in;
					word_length_out <= word_length_in;
					opcode_out <= opcode_in;
					
					if (!nop) begin
						we_reg_out <= we_reg_in;
						we_mem_out <= we_mem_in;
						is_load_out <= is_load_in;
					end
					
					else begin
						we_reg_out <= 1'b0;
						we_mem_out <= 1'b0;
						is_load_out <= 1'b0;
						// opcode_out stays as set in line 223 - needed for EBREAK/ECALL detection
					end
				end
			end 
endmodule 

module MEM_WB(PC_in, PC_4_in, ALU_result_in, imm_U_in, rd_in, we_reg_in, RF_sel_in, is_signed_in, word_length_in, data_mem_in, opcode_in,
				  PC_out, PC_4_out, ALU_result_out, imm_U_out, rd_out, we_reg_out, RF_sel_out, is_signed_out, word_length_out, data_mem_out, opcode_out, clk, rst);
				  
					input [31:0] PC_in, PC_4_in, ALU_result_in, imm_U_in;
                    input [31:0] data_mem_in;
					input [4:0] rd_in;
					input [2:0] RF_sel_in;
					input [1:0] word_length_in;
					input [6:0] opcode_in;
					input we_reg_in, is_signed_in, clk, rst;
					
					
					output reg [31:0]  PC_out, PC_4_out, ALU_result_out, imm_U_out;
                    output reg [31:0] data_mem_out;
					output reg [4:0] rd_out;
					output reg [2:0] RF_sel_out;
					output reg [1:0] word_length_out;
					output reg [6:0] opcode_out;
					output reg we_reg_out, is_signed_out;
					
					always @(posedge clk) begin
						if (rst) begin
							PC_out <= 32'b0;
							PC_4_out <= 32'b0;
							ALU_result_out <= 32'b0;
							imm_U_out <= 32'b0;
							rd_out <= 5'b0;
							RF_sel_out <= 3'b0;
							word_length_out <= 2'b0;
							opcode_out <= 7'b0;  // Reset opcode
							we_reg_out <= 1'b0;
							is_signed_out <= 1'b0;
                            data_mem_out <= 32'b0;
						end
						else begin
							PC_out <= PC_in;
							PC_4_out <= PC_4_in;
							ALU_result_out <= ALU_result_in;
							imm_U_out <= imm_U_in;
							rd_out <= rd_in;
							RF_sel_out <= RF_sel_in;
							we_reg_out <= we_reg_in;	
							is_signed_out <= is_signed_in;
							word_length_out <= word_length_in;
                            data_mem_out <= data_mem_in;
                            opcode_out <= opcode_in;
						end
					end
endmodule 