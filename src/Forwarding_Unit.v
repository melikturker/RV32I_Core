

module Forwarding_Unit( ALU_EX, ALU_MEM, data_WB, PC_EX, PC_MEM, PC_4_EX, PC_4_MEM, U_imm_EX, U_imm_MEM, U_imm_WB,
								rd_EX, rd_MEM, rd_WB, rs1_EX, rs2_EX,
								RF_sel_MEM, we_reg_MEM, we_reg_WB,
								FU_out1, FU_out2, sel1, sel2,
								is_load_MEM, stall, rst);
		
		input [31:0] ALU_EX, ALU_MEM, data_WB, PC_EX, PC_MEM, PC_4_EX, PC_4_MEM, U_imm_EX, U_imm_MEM, U_imm_WB;
		input [2:0] RF_sel_MEM;
		input [4:0] rd_EX, rd_MEM, rd_WB, rs1_EX, rs2_EX;
		input is_load_MEM, rst;
		input we_reg_MEM, we_reg_WB;
		
		
		output reg [31:0] FU_out1, FU_out2;
		output reg sel1, sel2, stall;
		

		always @(*) begin
			
			if(rst) begin
				sel1 = 1'b0;
				sel2 = 1'b0;
				stall = 1'b0;
			end
			
			else begin
			
				if (rs1_EX == rd_MEM && we_reg_MEM) begin 
				
					if (is_load_MEM) begin 
						stall = 1'b1;
					end
					
					else begin
				
						sel1 = 1'b1;
				
						if (RF_sel_MEM == 3'b000) FU_out1 = ALU_MEM;
						else if(RF_sel_MEM == 3'b010) FU_out1 = U_imm_MEM;
						else if(RF_sel_MEM == 3'b011) FU_out1 = PC_4_MEM;
						else if(RF_sel_MEM == 3'b100) FU_out1 = PC_MEM + U_imm_MEM;
						else if(RF_sel_MEM == 3'b101) FU_out1 = 32'b0;
						else if(RF_sel_MEM == 3'b110) FU_out1 = 32'hffffffff;
					end
				end
				
				
				if (rs2_EX == rd_MEM && we_reg_MEM) begin 
				
					sel2 = 1'b1;
					
					if (RF_sel_MEM == 3'b000) FU_out2 = ALU_MEM;
					else if(RF_sel_MEM == 3'b001) ; //Should be stalled for one cycle
					else if(RF_sel_MEM == 3'b010) FU_out2 = U_imm_MEM;
					else if(RF_sel_MEM == 3'b011) FU_out2 = PC_4_MEM;
					else if(RF_sel_MEM == 3'b100) FU_out2 = PC_MEM + U_imm_MEM;
					else if(RF_sel_MEM == 3'b101) FU_out1 = 32'b0;
					else if(RF_sel_MEM == 3'b110) FU_out1 = 32'hffffffff;
				
				end
				
				
				if (rs1_EX == rd_WB && we_reg_WB) begin 
					sel1 = 1'b1;
					FU_out1 = data_WB;
				end
				
				if (rs2_EX == rd_WB && we_reg_WB) begin 
					sel2 = 1'b1;
					FU_out2 = data_WB;
				end
				
				if(rs1_EX != rd_MEM && rs1_EX != rd_WB) sel1 = 1'b0;
				if(rs2_EX != rd_MEM && rs2_EX != rd_WB) sel2 = 1'b0;
				
				if (!(rs1_EX == rd_MEM || rs2_EX == rd_MEM || rs1_EX == rd_WB || rs2_EX == rd_WB))  begin // If any forwarding conditional is not activated
					stall = 1'b0;
					sel1 = 1'b0;
					sel2 = 1'b0;
				end
			
			end
		end

endmodule 