`timescale 1ns / 1ps

module RF(rs1, rs2, rd, data_in, out1, out2, we, clk);
	
	input we, clk;
	input [4:0] rs1;
	input [4:0] rs2;
	input [4:0] rd;
	input[31:0] data_in;

	output reg [31:0] out1;
	output reg [31:0] out2;
	
	reg 	[31:0] rf [31:0];
	
		always @(posedge clk) begin
			rf[0] = 32'b0;
				if (we) begin 
					rf[rd] = data_in;
					out1 = rf[rs1];
					out2 = rf[rs2];
				end
				else begin
					out1 = rf[rs1];
					out2 = rf[rs2];
				end 
		end
endmodule 