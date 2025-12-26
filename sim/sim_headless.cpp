#include <verilated.h>
#include "VSoC.h"
#include "VSoC___024root.h"
#include "VSoC_SoC.h"
#include "VSoC_Core.h"
#include "VSoC_I_mem.h"
#include "VSoC_D_mem.h"
#include "VSoC_Video_Mem.h"
#include "verilated_vcd_c.h"
#include "verilated_cov.h"

#include <iostream>
#include <iomanip>
#include <fstream>
#include <vector>
#include "common/VramDefines.h"
#include "common/SharedMemory.h"

// Constants
// Simulation time limit (in time units, 1 cycle = 10 time units)
const unsigned long long MAX_CYCLES = 10000000;  // 1M cycles
vluint64_t main_time = 0;

double sc_time_stamp() {
    return main_time;
}

#include <csignal>

bool stop_simulation = false;

void signal_handler(int signum) {
    stop_simulation = true;
}

// DPI Setup Function from sim_vram_dpi.cpp
extern "C" void setup_dpi_vram(uint32_t* vram, volatile uint32_t* refresh);

int main(int argc, char** argv) {
    // 1. Argument Parsing
    std::string test_file = "";
    std::string vcd_file = "trace.vcd";  // Default VCD filename
    bool dump_enabled = false;
    bool trace_enabled = false;
    bool interactive_mode = false;

    for (int i = 1; i < argc; i++) {
        std::string arg = argv[i];
        if (arg.find("+TESTFILE=") == 0) {
            test_file = arg.substr(10);
        } else if (arg.find("+VCD=") == 0) {
            vcd_file = arg.substr(5);
            trace_enabled = true;  // Auto-enable trace if VCD path given
        } else if (arg == "+DUMP") {
            dump_enabled = true;
        } else if (arg == "+TRACE") {
            trace_enabled = true;
        } else if (arg == "+INTERACTIVE") {
            interactive_mode = true;
        }
    }
    
    // ... (lines 40-101 are mostly same, just signal handler setup)

    if (interactive_mode) {
        std::signal(SIGINT, signal_handler);
        std::cout << "Interactive Mode: Running until Ctrl+C..." << std::endl;
    }

    if (test_file.empty()) {
        std::cerr << "Error: No +TESTFILE provided" << std::endl;
        return 1;
    }

    std::cout << "Starting Headless Simulation... (Waveform: " << (trace_enabled ? "ON" : "OFF") << ")" << std::endl;

    // 2. Initialize Shared Memory
    SharedMemory shm_vram(SHM_NAME, SHM_TOTAL_SIZE);
    if (!shm_vram.create()) {
        std::cerr << "Failed to create Shared Memory! Running without display output." << std::endl;
    } else {
        std::cout << "Shared Memory VRAM created." << std::endl;
    }

    uint32_t* vram_buffer = nullptr;
    volatile uint32_t* refresh_flag = nullptr;
    if (shm_vram.getPtr() != MAP_FAILED) {
        uint8_t* base_ptr = static_cast<uint8_t*>(shm_vram.getPtr());
        vram_buffer = reinterpret_cast<uint32_t*>(base_ptr);
        refresh_flag = reinterpret_cast<volatile uint32_t*>(base_ptr + OFFSET_REFRESH_FLAG);
        
        // Initialize DPI pointers
        setup_dpi_vram(vram_buffer, refresh_flag);
    }

    // 3. Setup Verilator
    Verilated::commandArgs(argc, argv);
    
    // Enable tracing if trace mode is enabled
    if (trace_enabled) {
        Verilated::traceEverOn(true);
    }
    
    // 3. Instantiate DUT
    VSoC* top = new VSoC;

    // Check for performance monitoring flag
    bool perf_enabled = false;
    for (int i = 1; i < argc; i++) {
        if (std::string(argv[i]) == "+PERF_ENABLE") {
            perf_enabled = true;
            break;
        }
    }
    
    if (perf_enabled) {
        top->perf_enable = 1;
        std::cout << "[SIM] Performance monitoring ENABLED" << std::endl;
    } else {
        top->perf_enable = 0;
    }

    // 4. Trace Setup
#if VM_TRACE
    VerilatedVcdC* tfp = nullptr;
    if (trace_enabled) {
        tfp = new VerilatedVcdC;
        top->trace(tfp, 99);
        tfp->open(vcd_file.c_str());
        std::cout << "[SIM] VCD trace enabled: " << vcd_file << std::endl;
    }
#endif

    // 5. Load Memory
    std::cout << "Loading I_mem from: " << test_file << std::endl;
    std::ifstream file(test_file);
    if (!file.is_open()) {
        std::cerr << "Error: Could not open hex file" << std::endl;
        return 1;
    }
    
    std::string line;
    int addr = 0;
    while (std::getline(file, line) && addr < 1024) { 
        try {
            uint32_t instr = std::stoul(line, nullptr, 16);
            top->rootp->SoC->core_inst->I_mem->Imem[addr] = instr;
            addr++;
        } catch (...) {}
    }
    file.close();

    // 6. Simulation Loop
    top->clk = 0;
    top->rst = 1; 

    bool finished = false;

    // Condition: 
    // If interactive: stop only on SIGINT or finish
    // If not interactive: stop on MAX_CYCLES or finish
    while (!Verilated::gotFinish() && !finished && !stop_simulation) {
        if (!interactive_mode && main_time >= MAX_CYCLES) break;

        if (main_time > 10) top->rst = 0; 
        
        if ((main_time % 5) == 0) top->clk = !top->clk; 

        top->eval();

#if VM_TRACE
        if (trace_enabled) tfp->dump(main_time);
#endif

        // --- VRAM Update Logic using Shared Memory ---
        // --- VRAM Update Logic (Legacy Copy Removed) ---
        // DPI-C handles writes instantly. We just clear the Verilog flag if set.
        bool new_frame = false;
        if (top->rootp->SoC->video_mem_inst->refresh_frame == 1) {
             top->rootp->SoC->video_mem_inst->refresh_frame = 0;
             new_frame = true;
        }
        
        main_time++;

        // --- Performance Reporting ---
        static auto last_time = std::chrono::steady_clock::now();
        static uint64_t last_cycles = 0;
        static int frames = 0;
        static uint64_t total_cycles_per_sec = 0;
        static uint64_t frame_count_per_sec = 0;

        if (new_frame) {
            frames++;
            // Calculate cycles since last frame for statistics? 
            // Better to just average over a second.
        }

        auto now = std::chrono::steady_clock::now();
        if (std::chrono::duration_cast<std::chrono::seconds>(now - last_time).count() >= 1) {
            double duration = std::chrono::duration<double>(now - last_time).count();
            uint64_t cycles = main_time - last_cycles;
            double khz = (cycles / duration) / 1000.0;
            double fps = frames / duration;
            double cycles_per_frame = (frames > 0) ? (double)cycles / frames : 0.0;
            
            std::cout << "[Sim Speed] " << std::fixed << std::setprecision(2) << khz << " KHz (" 
                      << (khz/1000.0) << " MHz) | " 
                      << "Simulated FPS: " << fps << " | "
                      << "Cycles/Frame: " << (uint64_t)cycles_per_frame << std::endl;
            
            last_time = now;
            last_cycles = main_time;
            frames = 0;
        }
    }

    if (dump_enabled) {
        // ... (Register dump logic - kept same)
        std::ofstream dmem_file("dmem_dump.txt");
         if (dmem_file.is_open()) {
             for (int addr = 0; addr < 2048; addr += 4) {
                  uint32_t word_addr = addr >> 2;
                  if (word_addr >= 512) break; 
                  uint32_t val = top->rootp->SoC->core_inst->D_mem->Memory[word_addr];
                  dmem_file << "M[" << std::dec << addr << "]: " << std::hex << std::setw(8) << std::setfill('0') << val << std::endl;
             }
             dmem_file.close();
         }
    }

#if VM_TRACE
    if (trace_enabled) {
        tfp->close();
    }
#endif

#if VM_COVERAGE
    Verilated::mkdir("logs");
    VerilatedCov::write("logs/coverage.dat");
#endif

    top->final();
    std::cout << "Simulation PASSED" << std::endl;
    delete top;
    // shm destructor closes shared memory automatically

    return 0;
}
