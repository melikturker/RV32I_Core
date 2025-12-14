module PC(sel, clk, rst, we_PC, rev_PC, PC_in, PC_out); // Program counter
	
	input clk, rst, we_PC, rev_PC;
	input [1:0] sel; // Unused if PC_in logic is external, but keeping to match port order
	input [31:0] PC_in; // This is mapped to PC_in in Core.v
	output reg [31:0] PC_out;
	
	always @(posedge clk) begin
        // $display("PC Update: rst=%b we_PC=%b PC_in=%h", rst, we_PC, PC_in);
		if (rst) begin
			PC_out <= 32'h0;
		end
		else begin 
			if (we_PC) begin
				if (rev_PC)
					PC_out <= PC_in; // This looks like it reverses? or just loads?
				else
					PC_out <= PC_in;
			end
		end
	end
endmodule