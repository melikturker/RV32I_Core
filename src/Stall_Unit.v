

module Stall_Unit(nop_ID, nop_EX, nop_MEM, we_ID, we_EX, rev_PC, we_PC, stall_FU, flush, rst); 

	input stall_FU, flush, rst;
	
	output reg  we_ID, we_EX, rev_PC, we_PC, nop_ID, nop_EX, nop_MEM;

	always @(*)begin 
		if(!rst) begin
		
			if (flush) begin 
				we_ID = 1'b1; 
				we_EX = 1'b1; 
				rev_PC = 1'b0;
				nop_ID = 1'b1;
				nop_EX = 1'b1; 
				nop_MEM = 1'b0;
				
				we_PC = 1'b1;
			end

			else if(stall_FU) begin
				we_ID = 1'b0; // Stops IF/ID Register
				we_EX = 1'b1; // Enables ID/EX Register to accept NOP
				rev_PC = 1'b0; // Don't revert PC, just freeze it
				nop_ID = 1'b0; // Pass invalid instruction to ID? No, we_ID=0 keeps valid.
				nop_EX = 1'b1; // A bubble injected to EX stage
				nop_MEM = 1'b0; // Do NOT clear MEM stage (Allow Load to proceed)
				
				we_PC = 1'b0; // Freeze PC
			end
			
			else begin
				we_ID = 1'b1;
				we_EX = 1'b1;
				rev_PC = 1'b0;
				nop_ID = 1'b0;
				nop_EX = 1'b0;
				nop_MEM = 1'b0;
				we_PC = 1'b1;
			end
		end
		
		else  begin // if rst 
			we_ID = 1'b1;
			we_EX = 1'b1; 
			rev_PC = 1'b0;
			nop_ID = 1'b0;
			nop_EX = 1'b0;
			nop_MEM = 1'b0;
			we_PC = 1'b1;
		end
	end
	
	

	
endmodule 