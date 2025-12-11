
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
			// Default values - critical for avoiding latches
			sel1 = 1'b0;
			sel2 = 1'b0;
			FU_out1 = 32'b0;
			FU_out2 = 32'b0;
			stall = 1'b0;
			
			if(!rst) begin
				// ---------------------------------------------------------
				// Forwarding Logic for RS1 (Source Register 1)
				// ---------------------------------------------------------
				if (rs1_EX != 5'b0) begin // Never forward x0
					
					// Priority 1: MEM Stage (Most recent)
					if (rs1_EX == rd_MEM && we_reg_MEM) begin
						
						if (is_load_MEM) begin
							stall = 1'b1; // Load-Use Hazard
						end
						else begin
							sel1 = 1'b1;
							case(RF_sel_MEM)
								3'b000: FU_out1 = ALU_MEM;
								3'b010: FU_out1 = U_imm_MEM;
								3'b011: FU_out1 = PC_4_MEM;
								3'b100: FU_out1 = PC_MEM + U_imm_MEM;
								3'b101: FU_out1 = 32'b0;
								3'b110: FU_out1 = 32'hffffffff;
								default: FU_out1 = 32'b0;
							endcase
						end
					end
					
					// Priority 2: WB Stage (Older)
					else if (rs1_EX == rd_WB && we_reg_WB) begin
						sel1 = 1'b1;
						FU_out1 = data_WB;
					end
				end

				// ---------------------------------------------------------
				// Forwarding Logic for RS2 (Source Register 2)
				// ---------------------------------------------------------
				if (rs2_EX != 5'b0) begin // Never forward x0
					
					// Priority 1: MEM Stage
					if (rs2_EX == rd_MEM && we_reg_MEM) begin
						
						if (is_load_MEM) begin
							stall = 1'b1; // Load-Use Hazard
						end
						else begin
							sel2 = 1'b1;
							case(RF_sel_MEM)
								3'b000: FU_out2 = ALU_MEM;
								3'b010: FU_out2 = U_imm_MEM;
								3'b011: FU_out2 = PC_4_MEM;
								3'b100: FU_out2 = PC_MEM + U_imm_MEM;
								3'b101: FU_out2 = 32'b0;
								3'b110: FU_out2 = 32'hffffffff;
								default: FU_out2 = 32'b0;
							endcase
						end
					end
					
					// Priority 2: WB Stage
					else if (rs2_EX == rd_WB && we_reg_WB) begin
						sel2 = 1'b1;
						FU_out2 = data_WB;
					end
				end
			end
		end
endmodule 