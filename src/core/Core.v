`timescale 1ns / 1ps

module Core (clk, rst, perf_enable, video_addr, video_data, video_we);

	input clk, rst;
	input perf_enable;              // Performance monitoring enable
	
    // Video Interface Ports
    output [31:0] video_addr;
    output [31:0] video_data;
    output video_we;
	
	wire [31:0] PC_IF, PC_ID, PC_EX, PC_MEM, PC_WB; 					// PC propagation through stages
	wire [31:0] PC_4_IF, PC_4_ID, PC_4_EX, PC_4_MEM, PC_4_WB; 		// PC + 4 propagation through stages
	wire [1:0] PC_sel;
	
	wire [1:0] op2_sel_ID, op2_sel_EX;
	wire [3:0] ALU_sel_ID, ALU_sel_EX;
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
	wire is_bubble_EX; // Robustness signal
	
	wire we_ID, we_ID2, we_EX, nop_CU, nop_ID, nop_ID2, nop_out_ID, nop_EX, nop_MEM;
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
	wire [6:0] opcode_EX, opcode;
	wire [2:0] func3_EX, funct3;
	wire [31:0] reg_out1_EX, reg_out2_EX, reg_out2_MEM; 											// Outputs of RF
	wire [31:0] D_mem_out; 																					// Output and input of D_mem. D_mem_in is not used, since it is directly connected to reg_out2.
	
	wire ready;																									// Ready signal of D-MEM to inform data cache.
    
    assign nop_CU = nop_ID2; // Connect Decode stage NOP to Control Unit
	
	always @(*) begin
		
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
	
	// ------------ Stall Unit ------------
	// Memory busy signals (not used yet, tie to 0)
	wire i_mem_busy = 1'b0;
	wire d_mem_busy = 1'b0;
	
	// Stall_Unit expects we_MEM and we_WB (write enable signals for each stage)
	// These are equivalent to we_reg signals from pipeline registers
	wire we_MEM = we_reg_MEM;  // From EX_MEM register
	wire we_WB = we_reg_WB;    // From MEM_WB register
	
	Stall_Unit SU(nop_ID, nop_EX, nop_MEM, we_ID, we_EX, rev_PC, we_PC, 
	              we_MEM, we_WB, stall_FU, i_mem_busy, d_mem_busy, flush, rst); 
	
	// ------------ Forwarding Unit ------------	
    // Workaround for Stuck is_load_EX: Validate with Opcode and Funct3
    wire is_load_real;
    assign is_load_real = is_load_EX && (opcode_EX == 7'b0000011) && (func3_EX == 3'b010);

    // Forwarding Unit
    Forwarding_Unit FU(ALU_out_EX, ALU_out_MEM, RF_in, PC_EX, PC_MEM, PC_4_EX, PC_4_MEM, U_imm_EX, U_imm_MEM, U_imm_WB,
                       rd_EX, rd_MEM, rd_WB, rs1_EX, rs2_EX, rs1, rs2,
                       RF_sel_MEM, we_reg_MEM, we_reg_WB,
                       FU_out1, FU_out2, FU_sel1, FU_sel2,
                       is_load_real, is_load_MEM, stall_FU, is_bubble_EX, rst);

	
	PC_sel_Unit PCU(opcode_EX, func3_EX, is_bubble_EX, Z, N, RF_sel_EX1, flush, RF_sel_EX2, PC_sel, rst);
	
	//module PC_sel_Unit(opcode, funct3, Z, N, RF_sel_in, flush, RF_sel_out, PC_sel, rst);
	
	
	// ------------ IF stage ------------
	PC PC(PC_sel, clk, rst, we_PC, rev_PC, PC_in, PC_IF); 
	
	I_mem I_mem(instr, PC_IF, we_ID, nop_ID, nop_CU, rst, clk);
	
	// PC_4 Logic
	assign PC_4_IF = PC_IF + 32'd4;
	
	
	
	// ------------ ID stage ------------
    wire [31:0] instr_ID; // Instruction in ID stage (Output of IF_ID)

	IF_ID IF_ID(PC_IF, PC_4_IF, instr, nop_ID, nop_ID2,  
					PC_ID, PC_4_ID, instr_ID, we_ID, nop_out_ID, rst, clk); 
	
	
	Decode Decoder(instr_ID, opcode, rd_ID, funct3, rs1, rs2, CU_info, I_imm_in, S_imm_in, B_imm_in, U_imm_in, J_imm_in);
	
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
			rs1_EX, rs2_EX, rd_EX, ALU_sel_EX, op2_sel_EX, RF_sel_EX1, we_mem_EX, we_reg_EX, is_load_EX, is_signed_EX, word_length_EX, is_bubble_EX, nop_EX, we_EX, clk, rst);

	// ------------ EX stage ------------

	
	ALU ALU(op1, op2, ALU_sel_EX, is_signed_EX, ALU_out_EX, Z, N);
	
	EX_MEM EX_MEM(PC_EX, PC_4_EX, ALU_out_EX, U_imm_EX, rd_EX, we_reg_EX, we_mem_EX, RF_sel_EX1, rs2_sel, is_load_real, is_signed_EX, word_length_EX,
					  PC_MEM, PC_4_MEM, ALU_out_MEM, U_imm_MEM, rd_MEM, we_reg_MEM, we_mem_MEM, RF_sel_MEM, reg_out2_MEM, is_load_MEM, is_signed_MEM, word_length_MEM, nop_MEM, clk, rst);
	
	// ------------ MEM stage ------------
	
	Store_Length_Unit SLU(reg_out2_MEM, word_length_MEM, byte_mask, SLU_out); // wire byte_mask will be replaced with word length signal. maybe word_length2
	
	
	D_mem D_mem(ALU_out_MEM, reg_out2_MEM, D_mem_out, we_mem_MEM, clk); 
	
    // Video Interface Logic
    // If address >= 0x8000, it's video memory.
    // Core's internal logic doesn't change, we just tap into the MEM stage signals.
    wire is_video_addr = (ALU_out_MEM >= 32'h00008000);
    
    // We only enable video write if it's a store instruction (we_mem_MEM) AND address is VRAM range
    assign video_we = we_mem_MEM && is_video_addr;
    assign video_addr = ALU_out_MEM;
    assign video_data = reg_out2_MEM;

	wire [31:0] D_mem_out_WB; // Pipeline register output for Load Data

	 MEM_WB MEM_WB(PC_MEM, PC_4_MEM, ALU_out_MEM, U_imm_MEM, rd_MEM, we_reg_MEM, RF_sel_MEM, is_signed_MEM, word_length_MEM, D_mem_out,
					  PC_WB, PC_4_WB, ALU_out_WB, U_imm_WB, rd_WB, we_reg_WB, RF_sel_WB, is_signed_WB, word_length_WB, D_mem_out_WB, clk, rst);
	
	// ------------ WB stage ------------
	
	Load_Length_Unit LLU(D_mem_out_WB, word_length_WB, is_signed_WB, LLU_out);

	// ------------ Performance Monitoring ------------
	
	// === Simple, Direct Signals ===
	
	// 1. Instruction Valid Signal - Simple Propagation
	// Generate valid in IF, propagate through pipeline, count at WB
	
	// IF: Valid if real instruction fetched (allow PC=0 for first instruction!)
	wire valid_IF = (instr != 32'h00000000);
	
	// ID: Propagate or clear on NOP
	reg valid_ID;
	always @(posedge clk) begin
		if (rst || nop_ID)
			valid_ID <= 0;
		else if (we_ID)
			valid_ID <= valid_IF;
		else
			valid_ID <= valid_ID;  // Hold
	end
	
	// EX: Propagate or clear on NOP
	// CRITICAL FIX: When flush happens, ID becomes NOP but EX instruction
	// is still valid! Don't overwrite with valid_ID=0 from flushed ID.
	// Solution: Only update if we_EX AND no flush, or hold.
	reg valid_EX;
	always @(posedge clk) begin
		if (rst || nop_EX)
			valid_EX <= 0;
		else if (we_EX && !flush)  // Don't take 0 from flushed ID!
			valid_EX <= valid_ID;
		else
			valid_EX <= valid_EX;  // Hold (including during flush)
	end
	
	// MEM: Propagate or clear on NOP
	reg valid_MEM;
	always @(posedge clk) begin
		if (rst || nop_MEM)
			valid_MEM <= 0;
		else
			valid_MEM <= valid_EX;
	end
	
	// WB: Propagate (final stage)
	reg valid_WB;
	always @(posedge clk) begin
		if (rst)
			valid_WB <= 0;
		else
			valid_WB <= valid_MEM;
	end
	
	// Retired: Count valid instructions at WB
	wire instruction_retired = valid_WB;
	
	// Track PC_IF for program finish detection
	reg [31:0] PC_IF_prev;
	always @(posedge clk) begin
		if (rst)
			PC_IF_prev <= 0;
		else
			PC_IF_prev <= PC_IF;
	end
	
	// 2. Stall: Direct from Forwarding Unit
	wire pipeline_stall = stall_FU;
	
	// 3. Bubble: NOP in EX or MEM
	wire pipeline_bubble = nop_EX || nop_MEM;
	
	// 4. RAW Hazard: Dependency detected (simplified)
	wire raw_hazard_ex_mem = ((rs1_EX == rd_MEM) || (rs2_EX == rd_MEM)) && (rd_MEM != 5'b0) && we_reg_MEM;
	wire raw_hazard_ex_wb = ((rs1_EX == rd_WB) || (rs2_EX == rd_WB)) && (rd_WB != 5'b0) && we_reg_WB;
	wire raw_hazard_detected = raw_hazard_ex_mem || raw_hazard_ex_wb;
	
	// 5. Forwarding: FU select signals
	wire forward_ex_to_ex = FU_sel1;
	wire forward_mem_to_ex = FU_sel2;
	
	// 6. Branch Metrics: Separate Conditional and Unconditional
	wire [6:0] opcode_ID = instr_ID[6:0];
	
	// Conditional branches (BEQ, BNE, BLT, BGE, BLTU, BGEU)
	wire is_cond_branch_ID = (opcode_ID == 7'b1100011);
	wire conditional_branch = is_cond_branch_ID && !nop_ID;
	
	// Unconditional jumps (JAL, JALR)
	wire is_jal_ID = (opcode_ID == 7'b1101111);
	wire is_jalr_ID = (opcode_ID == 7'b1100111);
	wire unconditional_branch = (is_jal_ID || is_jalr_ID) && !nop_ID;
	
	// 7. Flush: Track pipeline flushes (control-flow penalty)
	// Flush occurs on all control-flow changes (both conditional and unconditional)
	wire pipeline_flush = flush;
	
	
	// === Program Finish Detection ===
	// Stop counting when:
	// 1. 10 consecutive 0x00000000 instructions OR
	// 2. PC stuck (doesn't change for 10 cycles)
	// Note: PC_IF_prev is already defined in instruction tracking above
	reg program_finished;
	reg [3:0] zero_instr_count;
	reg [3:0] pc_stuck_count;
	
	always @(posedge clk) begin
		if (rst) begin
			program_finished <= 0;
			zero_instr_count <= 0;
			pc_stuck_count <= 0;
		end else if (!program_finished) begin
			// Check 1: Consecutive zero instructions
			if (instr == 32'h00000000)
				zero_instr_count <= zero_instr_count + 1;
			else
				zero_instr_count <= 0;
			
			// Check 2: PC stuck (not changing) - reuse PC_IF_prev
		if (PC_IF == PC_IF_prev)
			pc_stuck_count <= pc_stuck_count + 1;
		else
			pc_stuck_count <= 0;
		
		// Stop if either condition met
		if (zero_instr_count >= 10 || pc_stuck_count >= 10) begin
			program_finished <= 1;
			$display("[CORE] Program finished at cycle %d", perf_monitor.cycle_count);
			// Save metrics immediately (for headless tests that finish quickly)
			perf_monitor.save_metrics();
		end
		end
	end
	
	// Performance Monitor
	Performance_Monitor perf_monitor (
		.clk(clk),
		.rst(rst),
		.perf_enable(perf_enable),
		.instruction_retired(instruction_retired),
		.pipeline_stall(pipeline_stall),
		.pipeline_bubble(pipeline_bubble),
		.pipeline_flush(pipeline_flush),
		.raw_hazard_detected(raw_hazard_detected),
		.forward_ex_to_ex(forward_ex_to_ex),
		.forward_mem_to_ex(forward_mem_to_ex),
		.conditional_branch(conditional_branch),
		.unconditional_branch(unconditional_branch)
	);


endmodule
