/*
 * Performance Monitor Module
 * 
 * Tracks performance counters for pipeline analysis.
 * Only active when perf_enable is high.
 * 
 * Metrics tracked:
 * - Total cycles
 * - Instructions retired
 * - Stall cycles
 * - Forward events
 * - Branch events (taken, mispredictions)
 */

module Performance_Monitor (
    input wire clk,
    input wire rst,
    input wire perf_enable,          // Enable performance counting
    
    // Instruction tracking
    input wire instruction_valid,    // Valid instruction in pipeline
    input wire instruction_retired,  // Instruction completed (reached WB)
    
    // Pipeline events
    input wire stall,                // Pipeline stall
    input wire bubble,               // NOP injection (bubble)
    
    // Forwarding
    input wire forward_ex_to_ex,     // EX->EX forward
    input wire forward_mem_to_ex,    // MEM->EX forward
    input wire raw_hazard_detected,  // RAW hazard occurred
    
    // Branch tracking
    input wire branch_instruction,   // Branch/jump instruction
    input wire branch_taken,         // Branch was taken
    input wire branch_mispredicted   // Branch misprediction (flush)
);

    // Performance counters
    reg [31:0] cycle_count;
    reg [31:0] instruction_count;
    reg [31:0] stall_count;
    reg [31:0] bubble_count;
    reg [31:0] forward_count;
    reg [31:0] raw_hazard_count;
    reg [31:0] branch_count;
    reg [31:0] branch_taken_count;
    reg [31:0] branch_mispred_count;
    
    // Counter logic
    always @(posedge clk) begin
        if (rst) begin
            cycle_count <= 0;
            instruction_count <= 0;
            stall_count <= 0;
            bubble_count <= 0;
            forward_count <= 0;
            raw_hazard_count <= 0;
            branch_count <= 0;
            branch_taken_count <= 0;
            branch_mispred_count <= 0;
        end else if (perf_enable) begin
            // Count cycles (perf_enable controlled externally to stop when program ends)
            cycle_count <= cycle_count + 1;
            
            // Count retired instructions
            if (instruction_retired)
                instruction_count <= instruction_count + 1;
            
            // Count stalls
            if (stall)
                stall_count <= stall_count + 1;
            
            // Count bubbles
            if (bubble)
                bubble_count <= bubble_count + 1;
            
            // Count forwards
            if (forward_ex_to_ex || forward_mem_to_ex)
                forward_count <= forward_count + 1;
            
            // Count RAW hazards
            if (raw_hazard_detected)
                raw_hazard_count <= raw_hazard_count + 1;
            
            // Count branches
            if (branch_instruction) begin
                branch_count <= branch_count + 1;
                if (branch_taken)
                    branch_taken_count <= branch_taken_count + 1;
            end
            
            // Count mispredictions
            if (branch_mispredicted)
                branch_mispred_count <= branch_mispred_count + 1;
        end
    end
    
    // Task to save performance metrics to file
    task save_metrics;
        integer f;
        reg [31:0] adjusted_cycles;
        begin
            if (perf_enable) begin
                // Adjust cycle count: subtract 10 for zero detection overhead
                adjusted_cycles = (cycle_count > 10) ? (cycle_count - 10) : cycle_count;
                
                f = $fopen("logs/perf_counters.txt", "w");
                if (f) begin
                    $fwrite(f, "cycles=%0d\n", adjusted_cycles);
                    $fwrite(f, "instructions=%0d\n", instruction_count);
                    $fwrite(f, "stalls=%0d\n", stall_count);
                    $fwrite(f, "bubbles=%0d\n", bubble_count);
                    $fwrite(f, "forwards=%0d\n", forward_count);
                    $fwrite(f, "raw_hazards=%0d\n", raw_hazard_count);
                    $fwrite(f, "branches=%0d\n", branch_count);
                    $fwrite(f, "branch_taken=%0d\n", branch_taken_count);
                    $fwrite(f, "branch_mispred=%0d\n", branch_mispred_count);
                    $fclose(f);
                    $display("[PERF] Metrics saved to logs/perf_counters.txt");
                end else begin
                    $display("[PERF] ERROR: Could not open logs/perf_counters.txt");
                end
            end
        end
    endtask

endmodule
