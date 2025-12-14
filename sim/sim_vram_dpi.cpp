#include <iostream>
#include <fcntl.h>
#include <sys/mman.h>
#include <unistd.h>
#include <cstring>
#include "svdpi.h"
#include "common/VramDefines.h"
#include "common/SharedMemory.h"

// Global pointer for DPI function to access
static uint32_t* g_vram_buffer = nullptr;
static volatile uint32_t* g_refresh_flag = nullptr;

// Function to link the global pointer from sim_headless.cpp
extern "C" void setup_dpi_vram(uint32_t* vram, volatile uint32_t* refresh) {
    g_vram_buffer = vram;
    g_refresh_flag = refresh;
}

// DPI Export Implementation
extern "C" void dpi_vram_write(int address, int data) {
    // Address is byte address. Convert to word index.
    // Base is 0x8000.
    uint32_t offset = address - 0x8000;
    
    // Check range
    if (offset < SHM_TOTAL_SIZE) {
         // Direct Write (Zero Copy!)
         if (g_vram_buffer) {
             g_vram_buffer[offset >> 2] = data;
         }
    } else if (address == 0x54000) { // REFRESH_REG
         if (g_refresh_flag) {
             *g_refresh_flag = 1;
         }
    }
}
