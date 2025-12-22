

module Stall_Unit(nop_ID, nop_EX, nop_MEM, we_ID, we_EX, rev_PC, we_PC, we_MEM, we_WB, stall_FU, i_mem_busy, d_mem_busy, flush, rst); 

	input stall_FU, flush, rst, i_mem_busy, d_mem_busy;
	
	output reg  we_ID, we_EX, rev_PC, we_PC, nop_ID, nop_EX, nop_MEM, we_MEM, we_WB;

	always @(*)begin 
		// Default: Run Pipeline
		we_ID = 1'b1;
		we_EX = 1'b1;
		we_MEM = 1'b1;
		we_WB = 1'b1; 
		rev_PC = 1'b0;
		nop_ID = 1'b0;
		nop_EX = 1'b0;
		nop_MEM = 1'b0;
		we_PC = 1'b1;

		if(!rst) begin
		
			if (d_mem_busy || i_mem_busy) begin // Global Stall for both Memory/Fetch Stalls
				// Memory Stall: Freeze EVERYTHING
				// Do not flush/nop, just hold state.
				we_PC = 1'b0;
				we_ID = 1'b0;
				we_EX = 1'b0;
				we_MEM = 1'b0;
				we_WB = 1'b0;
			end
			else if (flush) begin 
				// Branch Mispredict: Flush ID and EX
				// PC is updated by Branch Logic (outside Stall Unit, PC_Sel)
				nop_ID = 1'b1;
				nop_EX = 1'b1; 
				// nop_MEM = 1'b0;
			end
			else if(stall_FU) begin
				// Load-Use Hazard: Stall Fetch/Decode, Inject NOP into EX
				we_PC = 1'b0; // Freeze PC
				we_ID = 1'b0; // Freeze IF/ID
				nop_EX = 1'b1; // Inject Bubble -> ID/EX
			end
			
		end
		
		else begin // Reset
			// Defaults are 1 (Wait, Reset usually clears registers)
			// But 'we' signals enable writing. If Reset is active, we validly write 0 to registers?
			// Stage_Regs handle Reset internally (Sync Reset or Async? Sync in code).
			// If Sync Reset, we needs to be 1?
			// Logic shows: we_ID=1 ...
		end
	end
	
endmodule 