`timescale 1ps / 1ps

module D_mem(address, data_in, data_out, we, clk);
	
	input we, clk;
	input [31:0] address;
	input [31:0] data_in;
	
	output reg [31:0] data_out;
	
	reg [31:0] Memory[511:0]; // 512 words (0x0000 - 0x07FF)
	
	// Address Decoding
	// wire is_vram = (address >= 32'h00008000); // Removed: Handled by Core/SoC now
	wire is_ram  = (address < 32'h00000800); // 512 words * 4 bytes = 2048 (0x800)
    
    // Video Memory Instance REMOVED
	
	// Write Logic (Synchronous)
	always @(posedge clk) begin
			if (we && is_ram) begin
			     // $display("D_MEM: Write [%h] <= %h", address, data_in);
			     Memory[address[31:2]] <= data_in;
			end
			
            // Read Logic (Synchronous)
            if (is_ram) begin
                // Note: Reading current value before write update (standard block RAM)
				data_out <= Memory[address[31:2]];
                // $display("D_MEM: Read [%h] -> %h", address, Memory[address[31:2]]);
            end else begin
                data_out <= 32'h0;
            end
	end

endmodule