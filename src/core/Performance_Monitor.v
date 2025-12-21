/*
 * Performance Monitor Module
 * 
 * Tracks performance counters for pipeline analysis.
 * Only active when perf_enable is high.
 * 
 * Metrics tracked:
 * - Total cycles
 * - Instructions retired
 * - Stall, bubble, and flush cycles
 * - Forwarding events
 * - Branch and jump counts
 */

module Performance_Monitor (
    input wire clk,
    input wire rst,
    input wire perf_enable,
    
    // Performance signals from Core
    input wire instruction_retired,
    input wire pipeline_stall,
    input wire pipeline_bubble,
    input wire pipeline_flush,
    input wire raw_hazard_detected,
    input wire forward_ex_to_ex,
    input wire forward_mem_to_ex,
    input wire conditional_branch,
    input wire unconditional_branch,
    
    // NEW: Instruction classification
    input wire [6:0] opcode_wb
);

    // Performance Counters
    reg [31:0] cycle_count;
    reg [31:0] instruction_count;
    reg [31:0] stall_count;
    reg [31:0] bubble_count;
    reg [31:0] flush_count;
    reg [31:0] forward_count;
    reg [31:0] raw_hazard_count;
    reg [31:0] cond_branch_count;
    reg [31:0] uncond_branch_count;
    
    // NEW: Instruction mix counters
    reg [31:0] alu_r_count;
    reg [31:0] alu_i_count;
    reg [31:0] load_count;
    reg [31:0] store_count;
    reg [31:0] branch_count;
    reg [31:0] jump_count;
    reg [31:0] system_count;
    
    // ============================================
    // INSTRUCTION CLASSIFICATION
    // ============================================
    wire is_alu_r  = (opcode_wb == 7'b0110011);  // R-type ALU
    wire is_alu_i  = (opcode_wb == 7'b0010011);  // I-type ALU
    wire is_load   = (opcode_wb == 7'b0000011);  // Load
    wire is_store  = (opcode_wb == 7'b0100011);  // Store
    wire is_branch = (opcode_wb == 7'b1100011);  // Branch
    wire is_jump   = (opcode_wb == 7'b1101111 || opcode_wb == 7'b1100111);  // JAL/JALR
    wire is_system = (opcode_wb == 7'b1110011 || opcode_wb == 7'b0001111);  // ECALL/EBREAK/FENCE
    
    // Counter logic
    always @(posedge clk) begin
        if (rst) begin
            cycle_count <= 0;
            instruction_count <= 0;
            stall_count <= 0;
            bubble_count <= 0;
            flush_count <= 0;
            forward_count <= 0;
            raw_hazard_count <= 0;
            cond_branch_count <= 0;
            uncond_branch_count <= 0;
            alu_r_count <= 0;
            alu_i_count <= 0;
            load_count <= 0;
            store_count <= 0;
            branch_count <= 0;
            jump_count <= 0;
            system_count <= 0;
        end else if (perf_enable) begin
            // Count cycles (perf_enable controlled externally to stop when program ends)
            cycle_count <= cycle_count + 1;
            
            if (instruction_retired && perf_enable)
                instruction_count <= instruction_count + 1;
            
                if (is_alu_r)  alu_r_count <= alu_r_count + 1;
                if (is_alu_i)  alu_i_count <= alu_i_count + 1;
                if (is_load)   load_count <= load_count + 1;
                if (is_store)  store_count <= store_count + 1;
                if (is_branch) branch_count <= branch_count + 1;
                if (is_jump)   jump_count <= jump_count + 1;
                if (is_system) system_count <= system_count + 1;
            if (pipeline_stall && perf_enable)
                stall_count <= stall_count + 1;
            
            if (pipeline_bubble && perf_enable)
                bubble_count <= bubble_count + 1;
            
            if (pipeline_flush && perf_enable)
                flush_count <= flush_count + 1;
        
            if (raw_hazard_detected && perf_enable)
                raw_hazard_count <= raw_hazard_count + 1;
            
            if ((forward_ex_to_ex || forward_mem_to_ex) && perf_enable)
                forward_count <= forward_count + 1;
            
            if (conditional_branch && perf_enable)
                cond_branch_count <= cond_branch_count + 1;
            
            if (unconditional_branch && perf_enable)
                uncond_branch_count <= uncond_branch_count + 1;
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
                    $fwrite(f, "flushes=%0d\n", flush_count);
                    $fwrite(f, "forwards=%0d\n", forward_count);
                    $fwrite(f, "raw_hazards=%0d\n", raw_hazard_count);
                    $fwrite(f, "cond_branches=%0d\n", cond_branch_count);
                    $fwrite(f, "uncond_branches=%0d\n", uncond_branch_count);
                    $fwrite(f, "alu_r=%0d\n", alu_r_count);
                    $fwrite(f, "alu_i=%0d\n", alu_i_count);
                    $fwrite(f, "load=%0d\n", load_count);
                    $fwrite(f, "store=%0d\n", store_count);
                    $fwrite(f, "branch=%0d\n", branch_count);
                    $fwrite(f, "jump=%0d\n", jump_count);
                    $fwrite(f, "system=%0d\n", system_count);
                    $fclose(f);
                    $display("[PERF] Metrics saved to logs/perf_counters.txt");
                end else begin
                    $display("[PERF] ERROR: Could not open logs/perf_counters.txt");
                end
            end
        end
    endtask
    
    // Auto-save metrics when simulation ends (Verilator final)
    final begin
        if (perf_enable) begin
            save_metrics();
        end
    end

endmodule
