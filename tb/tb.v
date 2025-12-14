`timescale 1ns / 1ps

module tb();
	
	reg clk, rst;

	integer idx;

	integer f;
	
	initial begin
		// $dumpfile("tb.vcd");
		// $dumpvars(0, tb);
	
		// Optional: Waveform dump logic
		// for (idx = 0; idx <= 31; idx = idx + 1) begin
		// 	$dumpvars(0, core.regFile.rf[idx]);
		// end
		
		clk = 0;
		rst = 1; #2;
		rst = 0;
		// Wait long enough for stress tests
		#2000000000; 
		
		// Dump Registers to File for Python Verification
		f = $fopen("reg_dump.txt", "w");
		for (idx = 0; idx < 32; idx = idx + 1) begin
			$fwrite(f, "x%0d: %h\n", idx, core.regFile.rf[idx]);
		end
		$fclose(f);
		
		// Dump Data Memory to File
		f = $fopen("dmem_dump.txt", "w");
		for (idx = 0; idx < 512; idx = idx + 1) begin
			$fwrite(f, "M[%0d]: %h\n", idx * 4, core.D_mem.Memory[idx]);
		end
		$fclose(f);
		
		$finish;
	end
		
	always #1 clk = !clk;
	
	Core core(clk, rst);
	
endmodule 
