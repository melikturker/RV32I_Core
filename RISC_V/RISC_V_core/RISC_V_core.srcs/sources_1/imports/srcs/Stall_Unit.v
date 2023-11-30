

module Stall_Unit(nop_ID, nop_EX, nop_MEM, we_ID, we_EX, rev_PC, we_PC, stall_FU, flush, rst); 

	input stall_FU, flush, rst;
	
	output reg  we_ID, we_EX, rev_PC, we_PC, nop_ID, nop_EX, nop_MEM;

	always @(*)begin 
		if(!rst) begin
		
			if(stall_FU) begin
				we_ID = 1'b0; // Stops IF/ID Register
				we_EX = 1'b0; // Stops ID/EX Register
				rev_PC = 1'b1; // PC - 4 operation is trigerred
				nop_ID = 1'b0; // A bubble injected to ID stage by IF/ID register
				nop_EX = 1'b0; // A bubble injected to EX stage by ID/EX register
				nop_MEM = 1'b1; // A bubble injected to MEM stage by EX/MEM register
				
				we_PC = 1'b1; // Enables to write new PC. Is it necessary !!!!
			end
			
			else if (flush) begin // else if or only if ???
				we_ID = 1'b1; // Is this necessary
				we_EX = 1'b1; // Is this necessary
				rev_PC = 1'b0;
				nop_ID = 1'b1;
				nop_EX = 1'b1; 
				nop_MEM = 1'b0;
				
				we_PC = 1'b1;
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