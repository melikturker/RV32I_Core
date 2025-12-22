`timescale 1ps / 1ps

module I_mem (instruction, address, we, nop_in, nop_out, rst, clk);

input we, nop_in, rst, clk;
input[31:0] address;
output reg [31:0]instruction;
output reg nop_out;

//memAddr is an address register in the memory side.
    // reg[31:0]memAddr; // Removed for combinational logic
reg[31:0]Imem[0:2047] /*verilator public*/;

//The I-Memory is initially loaded
    reg [1023:0] test_file_path;
initial begin
    if ($value$plusargs("TESTFILE=%s", test_file_path)) begin
        $display("Loading I_mem from: %0s", test_file_path);
        $readmemh(test_file_path, Imem);
    end else begin
        // Default fallback if no +TESTFILE argument
        $readmemh("src/memory/instructions/instr.txt", Imem);
    end
end

// Combinational Address Decoding
    wire [29:0] word_idx = address[31:2]; // Use 30 bits for index to match log
    
    assign nop_out = nop_in;

always @(*) begin 
if (rst) begin
instruction = 32'h00000013; // NOP
end
else if (nop_in) begin 
instruction = 32'h00000013;   // nop instruction. 
end 
else begin 
instruction = Imem[word_idx];
end
end
endmodule
