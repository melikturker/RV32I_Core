#ifndef VRAM_DEFINES_H
#define VRAM_DEFINES_H

#include <cstdint>

// Screen Dimensions
const int VRAM_WIDTH = 320;
const int VRAM_HEIGHT = 240;
const int VRAM_PIXEL_COUNT = VRAM_WIDTH * VRAM_HEIGHT;
const int VRAM_SIZE_BYTES = VRAM_PIXEL_COUNT * 4; // 32-bit ARGB

// Shared Memory Configuration
const char* const SHM_NAME = "/rv32i_vram_shm";
// Total size: VRAM Buffer + Control Flags
// Layout:
// [0 ... VRAM_SIZE_BYTES-1] : Pixel Data
// [VRAM_SIZE_BYTES]         : refresh_ready (uint32_t)
const int SHM_TOTAL_SIZE = VRAM_SIZE_BYTES + sizeof(uint32_t);

// Flag Offsets
const int OFFSET_REFRESH_FLAG = VRAM_SIZE_BYTES;

#endif // VRAM_DEFINES_H
