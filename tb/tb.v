`timescale 1ns / 1ps

module tb();
	
	reg clk, rst;

	integer idx;

	initial begin
		$dumpfile("tb.vcd");
		$dumpvars(0, tb);
		//$dumpvars(0, core.regFile.rf);
		//$dumpvars(0, core.I_mem.Imem);
	
		for (idx = 0; idx <= 31; idx = idx + 1) begin
			$dumpvars(0, core.regFile.rf[idx]);
		end

		for (idx = 0; idx <= 31; idx = idx + 1) begin
			$dumpvars(0, core.D_mem.Memory[idx]);
		end
		
		clk = 0;
		rst = 1; #2;
		rst = 0;
		#1000; $finish;
	end
		
	always #1 clk = !clk;
	
	Core core(clk, rst);
	
endmodule 
