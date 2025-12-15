# RISC-V Applications 🎮

Use these applications to demonstrate the capabilities of the RV32I Processor. They are written in RISC-V Assembly and interact with the processor's memory-mapped I/O.

## 🗺️ Memory Map

The processor uses a specific memory map to interact with the display peripheral.

| Region | Start Address | End Address | Description |
|--------|---------------|-------------|-------------|
| **VRAM** | `0x00008000` | `0x00053000` | Video Memory (640x480 pixels). Each byte maps to a pixel (8-bit color). |
| **Control**| `0x00054000` | - | Refresh Trigger. Writing to this address forces a frame update. |

> **Note:** The applications simply write to these addresses using `SB` (Store Byte) or `SW` (Store Word) instructions. The C++ Simulation wrapper captures these writes via DPI to render the graphics window.

## Available Demos

### 1. `colors.s`
**Purpose**: Basic Pipeline & Store Verification.
*   **Logic**: Iterates through the VRAM address space.
*   **Visual**: Draws a color gradient pattern. 
*   **Key Instruction**: `sw` (Store Word) in a tight loop.

### 2. `audio_bars.s` 🎵
**Purpose**: Complex Logic & Interactive Simulation.
*   **Origin**: Originally designed for an **ARM Cortex M0** processor in the **BLG 212E (Microprocessor Systems)** course.
*   **Logic**: 
    - Simulates "Audio Input" values using a pseudo-random generator.
    - Calculates bar heights based on these values.
    - Implements "Gravity/Decay" physics to lower the bars gradually.
    - Renders the bars to VRAM.
*   **Visual**: A dynamic spectrum analyzer effect.

## Running Applications

Use the CLI to run these apps in GUI mode:

```bash
# Run Audio Bars
../runner.py run --gui audio_bars.s
```
