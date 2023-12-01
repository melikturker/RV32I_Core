`timescale 1ns / 1ps

module tb();
	
	reg clk, rst;

	initial begin
		clk = 0;
		rst = 1; #2;
		rst = 0;
	end
		
	always #1 clk = !clk;
	
	Core core(clk, rst);
	
endmodule 