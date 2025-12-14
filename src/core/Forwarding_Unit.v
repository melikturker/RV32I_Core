module Forwarding_Unit( ALU_EX, ALU_MEM, data_WB, PC_EX, PC_MEM, PC_4_EX, PC_4_MEM, U_imm_EX, U_imm_MEM, U_imm_WB,
								rd_EX, rd_MEM, rd_WB, rs1_EX, rs2_EX, rs1_ID, rs2_ID,
								RF_sel_MEM, we_reg_MEM, we_reg_WB,
								FU_out1, FU_out2, sel1, sel2,
								is_load_EX, is_load_MEM, stall, is_bubble_EX, rst);
                                
    input is_bubble_EX; // Robustness Input
		
		input [31:0] ALU_EX, ALU_MEM, data_WB, PC_EX, PC_MEM, PC_4_EX, PC_4_MEM, U_imm_EX, U_imm_MEM, U_imm_WB;
		input [2:0] RF_sel_MEM;
		input [4:0] rd_EX, rd_MEM, rd_WB, rs1_EX, rs2_EX, rs1_ID, rs2_ID;
		input is_load_EX, is_load_MEM, rst;
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
				// Stall Logic (Load-Use Hazard)
				// ---------------------------------------------------------
				// If instruction in EX is a Load that writes to a register
				// used by the instruction currently in ID, we must stall.
				// This prevents the ID instruction from advancing to EX with stale data.
				if (is_load_EX && !is_bubble_EX && rd_EX != 5'b0) begin
					if (rd_EX == rs1_ID || rd_EX == rs2_ID) begin
						stall = 1'b1;

					end
				end

				// ---------------------------------------------------------
				// Forwarding Logic for RS1 (Source Register 1)
				// ---------------------------------------------------------
				if (rs1_EX != 5'b0) begin // Never forward x0
					
					// Priority 1: MEM Stage (Most recent instruction in pipeline ahead of EX)
					if (rs1_EX == rd_MEM && we_reg_MEM && rd_MEM != 5'b0) begin
						// Note: If MEM instruction is a Load, we can't forward here (data is in D-Mem).
						// But the Stall Logic above handles the case where expected data was Load.
						// Wait, Stall Logic handles Load(EX) vs Use(ID).
						// What if Load(MEM) vs Use(EX)?
						// If Load is in MEM, its result is NOT ready until WB stage.
						// MIPS: Load result ready at WB.
						// Forwarding from WB works.
						// Does forwarding from MEM work for Load? No.
						// But we rely on Bubble from previous Stall cycle?
						// Cycle T: Load(EX), Use(ID) -> Stall ID. Use stays in ID. Load goes to MEM.
						// Cycle T+1: Load(MEM), Use(ID). No Stall needed (ID registers checked against EX).
						//            Use proceeds to EX.
						// Cycle T+2: Load(WB), Use(EX). Result ready in WB. Forwarding works from WB!
						
						// However, we must ensure we DON't mistakenly forward ALU_MEM if it's a Load instruction.
						if (!is_load_MEM) begin 
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
					else if (rs1_EX == rd_WB && we_reg_WB && rd_WB != 5'b0) begin
						sel1 = 1'b1;
						FU_out1 = data_WB;
					end
				end

				// ---------------------------------------------------------
				// Forwarding Logic for RS2 (Source Register 2)
				// ---------------------------------------------------------
				if (rs2_EX != 5'b0) begin // Never forward x0
					
					// Priority 1: MEM Stage
					if (rs2_EX == rd_MEM && we_reg_MEM && rd_MEM != 5'b0) begin
						
						if (!is_load_MEM) begin
							sel2 = 1'b1;
                            if (RF_sel_MEM == 3'b000) begin
                                FU_out2 = ALU_MEM;

                            end
                            else if (RF_sel_MEM == 3'b010) FU_out2 = U_imm_MEM;
                            else if (RF_sel_MEM == 3'b011) FU_out2 = PC_4_MEM;
                            else if (RF_sel_MEM == 3'b100) FU_out2 = PC_MEM + U_imm_MEM;
                            else if (RF_sel_MEM == 3'b101 || RF_sel_MEM == 3'b111) FU_out2 = 32'b0;
                            else if (RF_sel_MEM == 3'b110) FU_out2 = 32'hffffffff;
                            else begin
                                FU_out2 = 32'b0;

                            end
						end
					end
					
					// Priority 2: WB Stage
					else if (rs2_EX == rd_WB && we_reg_WB && rd_WB != 5'b0) begin
						sel2 = 1'b1;
						FU_out2 = data_WB;
					end
				end
			end
        // Debug
        // if (rs2_EX == 5'd8 && sel2)
        //    $display("FWD: SW Trig! Val=%h (ALU_MEM=%h WB=%h) RF_sel=%b we_MEM=%b rd_MEM=%d", FU_out2, ALU_MEM, data_WB, RF_sel_MEM, we_reg_MEM, rd_MEM);

	end
endmodule