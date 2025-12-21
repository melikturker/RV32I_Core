`timescale 1ns / 1ps

module SoC(
    input clk,
    input rst,
    input perf_enable,
    output program_finished
);

    // Core Wires
    wire [31:0] video_addr;
    wire [31:0] video_data;
    wire video_we;

    // Instantiate Core
    Core core_inst (
        .clk(clk),
        .rst(rst),
        .perf_enable(perf_enable),
        .program_finished(program_finished),
        .video_addr(video_addr),
        .video_data(video_data),
        .video_we(video_we)
    );

    // Instantiate Video Memory
    // The Core handles address filtering, so we connect directly to video ports.
    // Video_Mem expects absolute address for its internal logic (if any), 
    // or we might need to adjust it. Based on previous file, it takes 32-bit address.
    Video_Mem video_mem_inst (
        .clk(clk),
        .we(video_we),
        .address(video_addr),
        .data_in(video_data)
    );

endmodule
