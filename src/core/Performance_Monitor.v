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
    input wire perf_enable,
    
    // Performance signals from Core
    input wire instruction_retired,
    input wire pipeline_stall,
    input wire pipeline_bubble,
    input wire raw_hazard_detected,
    input wire forward_ex_to_ex,
    input wire forward_mem_to_ex,
    input wire conditional_branch,
    input wire unconditional_branch,
    input wire conditional_mispred
);

    // Performance Counters
    reg [31:0] cycle_count;
    reg [31:0] instruction_count;
    reg [31:0] stall_count;
    reg [31:0] bubble_count;
    reg [31:0] forward_count;
    reg [31:0] raw_hazard_count;
    reg [31:0] cond_branch_count;
    reg [31:0] uncond_branch_count;
    reg [31:0] cond_mispred_count;
    
    // Counter logic
    always @(posedge clk) begin
        if (rst) begin
            cycle_count <= 0;
            instruction_count <= 0;
            stall_count <= 0;
            bubble_count <= 0;
            forward_count <= 0;
            raw_hazard_count <= 0;
            cond_branch_count <= 0;
            uncond_branch_count <= 0;
            cond_mispred_count <= 0;
        end else if (perf_enable) begin
            // Count cycles (perf_enable controlled externally to stop when program ends)
            cycle_count <= cycle_count + 1;
            
            if (instruction_retired && perf_enable)
                instruction_count <= instruction_count + 1;
            
            if (pipeline_stall && perf_enable)
                stall_count <= stall_count + 1;
            
            if (pipeline_bubble && perf_enable)
                bubble_count <= bubble_count + 1;
        
            if (raw_hazard_detected && perf_enable)
                raw_hazard_count <= raw_hazard_count + 1;
            
            if ((forward_ex_to_ex || forward_mem_to_ex) && perf_enable)
                forward_count <= forward_count + 1;
            
            if (conditional_branch && perf_enable)
                cond_branch_count <= cond_branch_count + 1;
            
            if (unconditional_branch && perf_enable)
                uncond_branch_count <= uncond_branch_count + 1;
            
            if (conditional_mispred && perf_enable)
                cond_mispred_count <= cond_mispred_count + 1;
        end
    end
    
    // Task to save performance metrics to file
    task save_metrics;
        integer f;
        reg [31:0] adjusted_cycles;
        begin
            if (perf_enable) begin
                // Adjust cycle count: subtract 10 for zero detection overhead
                /* verilator lint_off BLKSEQ */
                adjusted_cycles = (cycle_count > 10) ? (cycle_count - 10) : cycle_count;
                
                f = $fopen("logs/perf_counters.txt", "w"); // Blocking OK for system tasks
                /* verilator lint_on BLKSEQ */
                if (f) begin
                    $fwrite(f, "cycles=%0d\n", adjusted_cycles);
                    $fwrite(f, "instructions=%0d\n", instruction_count);
                    $fwrite(f, "stalls=%0d\n", stall_count);
                    $fwrite(f, "bubbles=%0d\n", bubble_count);
                    $fwrite(f, "forwards=%0d\n", forward_count);
                    $fwrite(f, "raw_hazards=%0d\n", raw_hazard_count);
                    $fwrite(f, "cond_branches=%0d\n", cond_branch_count);
                    $fwrite(f, "uncond_branches=%0d\n", uncond_branch_count);
                    $fwrite(f, "cond_mispred=%0d\n", cond_mispred_count);
                    $fclose(f);
                    $display("[PERF] Metrics saved to logs/perf_counters.txt");
                end else begin
                    $display("[PERF] ERROR: Could not open logs/perf_counters.txt");
                end
            end
        end
    endtask

endmodule
