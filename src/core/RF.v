`timescale 1ns / 1ps

module RF(rs1, rs2, rd, data_in, out1, out2, we, clk);
	
	input we, clk;
	input [4:0] rs1;
	input [4:0] rs2;
	input [4:0] rd;
	input[31:0] data_in;

	output reg [31:0] out1;
	output reg [31:0] out2;
	
	reg 	[31:0] rf [31:0] /*verilator public*/;
	
	integer i;
	initial begin
		for (i = 0; i < 32; i = i + 1) begin
			rf[i] = 32'b0;
		end
	end
	
	always @(posedge clk) begin
		rf[0] <= 32'b0;
		if (we && rd != 0) begin 
			rf[rd] <= data_in;
			// Internal Forwarding (Write-Through)
			// If reading the register being written in the same cycle, output new data.
			if (rs1 == rd && rd != 0) out1 <= data_in;
			else out1 <= rf[rs1];
			
			if (rs2 == rd && rd != 0) out2 <= data_in;
			else out2 <= rf[rs2];
		end
		else begin
			out1 <= rf[rs1];
			out2 <= rf[rs2];
		end 
	end
endmodule 