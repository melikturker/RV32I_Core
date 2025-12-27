#include <verilated.h>
#include "VSoC.h"
#include "VSoC.h"
#include "VSoC___024root.h"
#include "VSoC_SoC.h"
#include "VSoC_Video_Mem.h"
#include <SDL2/SDL.h>
#include <iostream>
#include <fstream>

// Constants
const int WIDTH = 320;
const int HEIGHT = 240;
const int SCALE = 2; // Window scaling

// Global Simulation Time
vluint64_t main_time = 0;

double sc_time_stamp() {
    return main_time;
}

// DPI Setup Function from sim_vram_dpi.cpp
extern "C" void setup_dpi_vram(uint32_t* vram, volatile uint32_t* refresh);

int main(int argc, char** argv) {
    // 1. Initialize Verilator
    Verilated::commandArgs(argc, argv);
    Verilated::traceEverOn(true);

    // 2. Initialize Model
    VSoC* top = new VSoC;

    // VRAM Buffer for DPI
    uint32_t* vram_buffer = new uint32_t[WIDTH * HEIGHT];
    // Clear VRAM
    for(int i=0; i<WIDTH*HEIGHT; i++) vram_buffer[i] = 0;

    // Setup DPI (Connect C++ buffer to Verilog DPI calls)
    // We pass the pointer to the Refresh flag inside Verilator model as well
    setup_dpi_vram(vram_buffer, &top->rootp->SoC->video_mem_inst->refresh_frame);

    // 3. Initialize SDL
    if (SDL_Init(SDL_INIT_VIDEO) < 0) {
        std::cerr << "SDL Init Failed: " << SDL_GetError() << std::endl;
        return 1;
    }

    SDL_Window* window = SDL_CreateWindow(
        "RV32I Verilator Core",
        SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED,
        WIDTH * SCALE, HEIGHT * SCALE,
        SDL_WINDOW_SHOWN
    );
    if (!window) {
        std::cerr << "SDL Window Creation Failed: " << SDL_GetError() << std::endl;
        return 1;
    }

    SDL_Renderer* renderer = SDL_CreateRenderer(window, -1, SDL_RENDERER_ACCELERATED);
    if (!renderer) {
        std::cerr << "SDL Renderer Failed: " << SDL_GetError() << std::endl;
        return 1;
    }

    SDL_Texture* texture = SDL_CreateTexture(
        renderer,
        SDL_PIXELFORMAT_ARGB8888,
        SDL_TEXTUREACCESS_STREAMING,
        WIDTH, HEIGHT
    );
    if (!texture) {
        std::cerr << "SDL Texture Failed: " << SDL_GetError() << std::endl;
        return 1;
    }

    // Pixel Buffer
    uint32_t* pixels = new uint32_t[WIDTH * HEIGHT];

    // 4. Simulation Loop
    bool quit = false;
    SDL_Event e;
    
    // Load Application Hex (handled by Verilog $readmemh in I_mem typically)
    
    // Check for +TEST_ENABLE plusarg
    bool test_enabled = false;
    for (int i = 1; i < argc; i++) {
        if (std::string(argv[i]) == "+TEST_ENABLE") {
            test_enabled = true;
            break;
        }
    }
    
    if (test_enabled) {
        std::cout << "[SIM] Test mode enabled (perf monitoring + dumps)" << std::endl;
        top->test_enable = 1;
    } else {
        top->test_enable = 0;
    }
    
    std::cout << "Starting Simulation Loop..." << std::endl;

    while (!Verilated::gotFinish() && !quit) {
        // if (main_time < 10) std::cout << "Cycle: " << main_time << std::endl;
        
        // Handle SDL Events (only check every 10000 cycles to reduce overhead)
        if (main_time % 10000 == 0) {
            while (SDL_PollEvent(&e) != 0) {
                if (e.type == SDL_QUIT) quit = true;
            }
        }

        // Toggle Clock
        top->clk = 1;
        top->eval();
        main_time++;

        top->clk = 0;
        top->eval();
        main_time++;
        
        // Reset logic (First 10 cycles)
        if (main_time < 20) top->rst = 1; else top->rst = 0; // Active High Reset (if(rst) ... in Verilog) 
        // Checking Core.v: input clk, rst; 
        // Usually rst is Active Low if logical (checks Core.v line 56: if(!rst) ...).
        // Yes, !rst implies Active Low. So 0 = Reset, 1 = Run.

        // Check Refresh Signal (We need to map this or just poll VRAM)
        // Since we have direct VRAM access, we can render every frame (or every N cycles).
        // Rendering every cycle is too slow (SDL overhead).
        // Let's render every 100,000 cycles (approx 320x240 pixels written).
        
        // Check Refresh Signal from Video_Mem
        // Path: top->rootp->Core->D_mem->vram_inst->refresh_frame
        if (top->rootp->SoC->video_mem_inst->refresh_frame == 1) {
            
            // Direct VRAM Access
            // const uint32_t* vram_ptr = &top->rootp->SoC->video_mem_inst->VRAM[0];
            
            // Debug log disabled for performance
            // std::cout << "[Visualizer] Frame Refresh Triggered at Cycle: " << main_time << std::endl;
             
             // Update Texture directly from VRAM pointer
             SDL_UpdateTexture(texture, NULL, (void*)vram_buffer, WIDTH * 4);
             
             SDL_RenderClear(renderer);
             SDL_RenderCopy(renderer, texture, NULL, NULL);
             SDL_RenderPresent(renderer);
             
             // Acknowledge/Reset the flag
             top->rootp->SoC->video_mem_inst->refresh_frame = 0;
        }
    }

    // Cleanup (Performance metrics auto-saved via Verilog final block)
    top->final();
    SDL_DestroyTexture(texture);
    SDL_DestroyRenderer(renderer);
    SDL_DestroyWindow(window);
    SDL_Quit();
    delete top;
    delete[] pixels;

    return 0;
}
