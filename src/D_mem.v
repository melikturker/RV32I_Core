`timescale 1ps / 1ps

module D_mem(address, data_in, data_out, we, clk);
	
	input we, clk;
	input [31:0] address;
	input [31:0] data_in;
	
	output reg [31:0] data_out;
	
	reg [31:0] Memory[511:0]; // 512 words 
	
	always @(posedge clk) begin
	
			if (we) begin
			     // $display("D_MEM WRITE: Addr=%d (Index %d) Data=%h", address, address[31:2], data_in);
			     Memory[address[31:2]] <= data_in;
			end
			else begin
				data_out <= Memory[address[31:2]];
			end
	end
endmodule 