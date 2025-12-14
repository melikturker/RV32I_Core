module Video_Mem(
    input clk,
    input we,
    input [31:0] address,
    input [31:0] data_in
);

    // DPI Imports
    import "DPI-C" function void dpi_vram_write(input int addr, input int data);

    // No internal storage! Directly bridging to C++
    
    initial begin
        refresh_frame = 0;
    end

    localparam REFRESH_ADDR = 32'h54000;
    localparam VRAM_BASE_ADDR = 32'h8000;
    
    // Kept for backward compatibility if any internal logic uses it, 
    // but effectively unused for storage.
    reg [31:0] refresh_frame /*verilator public*/; 
    
    always @(posedge clk) begin
        if (we) begin
            // Whether it is VRAM or REFRESH write, we send it to C++
            // C++ handles address decoding for VRAM vs Refresh logic.
            dpi_vram_write(address, data_in);
            
            // Keep internal flag logic for legacy compatibility if needed
            if (address == REFRESH_ADDR) begin
                refresh_frame <= 1'b1;
            end
        end
    end
endmodule
