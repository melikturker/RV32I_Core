`timescale 1ps / 1ps

module I_mem (instruction, address, we, nop_in, nop_out, rst, clk);

input we, nop_in, rst, clk;
input	[31:0] address;
output reg [31:0]	instruction;
output reg nop_out;

//	memAddr is an address register in the memory side.
reg	[31:0]	memAddr;
reg	[31:0]	Imem[0:2047];

	//	The I-Memory is initially loaded
    reg [1023:0] test_file_path;
initial begin
    if ($value$plusargs("TESTFILE=%s", test_file_path)) begin
        $display("Loading I_mem from: %0s", test_file_path);
        $readmemh(test_file_path, Imem);
    end else begin
        $display("Loading default instructions/instr.txt");
        $readmemh("instructions/instr.txt", Imem);
    end
end

	always @(posedge clk) begin 
        //$display("I_MEM: AddrInput=%h (%0d) | NopIn=%b", address, address, nop_in);
		nop_out = nop_in;
		
		if (rst) begin
			instruction = 32'h00000013;
            // $display("I_MEM: RST");
		end
		else if (nop_in) begin 
			instruction = 32'h00000013;   // nop instruction. 
            // $display("I_MEM: NOP Inserted");
		end 
		else begin 
			memAddr = address[31:2]; // Blocking assignment required for correct sim timing
			instruction = Imem[memAddr];
            // $display("I_MEM: Read Addr=%h (Idx %h) -> Instr=%h", address, address[31:2], Imem[memAddr]);
		end
	end
endmodule