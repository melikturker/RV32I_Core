#include <SDL2/SDL.h>
#include <iostream>
#include <thread>
#include <chrono>
#include "../common/VramDefines.h"
#include "../common/SharedMemory.h"

int main(int argc, char* argv[]) {
    // 1. Initialize SDL
    if (SDL_Init(SDL_INIT_VIDEO) < 0) {
        std::cerr << "SDL could not initialize! SDL_Error: " << SDL_GetError() << std::endl;
        return 1;
    }

    SDL_Window* window = SDL_CreateWindow("RV32I Virtual Screen",
                                          SDL_WINDOWPOS_UNDEFINED, SDL_WINDOWPOS_UNDEFINED,
                                          VRAM_WIDTH * 2, VRAM_HEIGHT * 2, // Scale 2x
                                          SDL_WINDOW_SHOWN);
    if (!window) {
        std::cerr << "Window could not be created! SDL_Error: " << SDL_GetError() << std::endl;
        return 1;
    }

    SDL_Renderer* renderer = SDL_CreateRenderer(window, -1, SDL_RENDERER_ACCELERATED);
    SDL_Texture* texture = SDL_CreateTexture(renderer, SDL_PIXELFORMAT_ARGB8888,
                                             SDL_TEXTUREACCESS_STREAMING,
                                             VRAM_WIDTH, VRAM_HEIGHT);

    // 2. Connect to Shared Memory
    SharedMemory shm(SHM_NAME, SHM_TOTAL_SIZE);
    std::cout << "Waiting for simulator to start..." << std::endl;

    // Retry loop until shared memory is available
    while (!shm.open()) {
        SDL_Event e;
        if (SDL_PollEvent(&e) && e.type == SDL_QUIT) return 0; // Allow exit while waiting
        std::this_thread::sleep_for(std::chrono::milliseconds(500));
    }
    std::cout << "Connected to Shared Memory!" << std::endl;

    // 3. Pointer setup
    uint8_t* base_ptr = static_cast<uint8_t*>(shm.getPtr());
    uint32_t* vram_buffer = reinterpret_cast<uint32_t*>(base_ptr);
    volatile uint32_t* refresh_flag = reinterpret_cast<volatile uint32_t*>(base_ptr + OFFSET_REFRESH_FLAG);

    // 4. Main Loop
    bool quit = false;
    SDL_Event e;

    while (!quit) {
        // Handle SDL Events
        while (SDL_PollEvent(&e) != 0) {
            if (e.type == SDL_QUIT) {
                quit = true;
            }
        }

        // Check for refresh signal
        if (*refresh_flag == 1) {
            // Update Texture
            SDL_UpdateTexture(texture, NULL, vram_buffer, VRAM_WIDTH * 4);
            
            // Render
            SDL_RenderClear(renderer);
            SDL_RenderCopy(renderer, texture, NULL, NULL);
            SDL_RenderPresent(renderer);

            // Acknowledge refresh
            *refresh_flag = 0;
        } else {
            // Very short sleep to minimize latency while avoiding 100% CPU
            std::this_thread::sleep_for(std::chrono::microseconds(1));
        }
    }

    // Cleanup
    SDL_DestroyTexture(texture);
    SDL_DestroyRenderer(renderer);
    SDL_DestroyWindow(window);
    SDL_Quit();
    // shm destructor handles cleanup

    return 0;
}
