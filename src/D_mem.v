`timescale 1ps / 1ps

module D_mem(address, data_in, data_out, we, clk);
	
	input we, clk;
	input [31:0] address;
	input [31:0] data_in;
	
	output reg [31:0] data_out;
	
	reg [31:0] Memory[31:0]; // There might be 2^32 place in memery. But only 32 implemented to ease visualisation. 
	
	always @(posedge clk) begin
	
			if (we) begin
			     Memory[address] <= data_in;
			end
			else begin
				data_out <= Memory[address];
			end
	end
endmodule 