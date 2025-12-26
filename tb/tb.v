`timescale 1ns / 1ps

module tb();
	
	reg clk, rst;
	reg perf_enable;

	integer idx;
	
	initial begin
	
		// Read performance monitoring flag from command line
		if ($test$plusargs("PERF_ENABLE")) begin
			perf_enable = 1;
		end else begin
			perf_enable = 0;
		end
		
		clk = 0;
		rst = 1; #2;
		rst = 0;
		
		#2000000000; // Wait long enough for stress tests

		core.perf_monitor.save_metrics(); // Save performance metrics if enabled
		
		$finish;
	end
		
	always #1 clk = !clk;
	
	Core core(clk, rst, perf_enable);
	
endmodule 
