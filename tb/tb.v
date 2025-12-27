`timescale 1ns / 1ps

module tb();
	
	reg clk, rst;
	reg test_enable;

	integer idx;
	
	initial begin
	
		// Read test enable flag from command line (enables perf monitoring + dumps)
		if ($test$plusargs("TEST_ENABLE")) begin
			test_enable = 1;
		end else begin
			test_enable = 0;
		end
		
		clk = 0;
		rst = 1; #2;
		rst = 0;
		
		#2000000000; // Wait long enough for stress tests

		core.perf_monitor.save_metrics(); // Save performance metrics if enabled
		
		$finish;
	end
		
	always #1 clk = !clk;
	
	Core core(clk, rst, test_enable);
	
endmodule 
