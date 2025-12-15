# RV32I Processor Core

A synthesized, 5-stage pipelined RISC-V processor implementation in Verilog. This project provides a complete cycle-accurate simulation environment, including a verification suite with coverage analysis and a memory-mapped graphical output system.

## 📌 Navigation
*   [Features](#-features)
*   [Architecture](#-architecture)
*   [Directory Structure](#-directory-structure)
*   [Quick Start (CLI)](#-quick-start-cli)
*   [Verification & Coverage](#-verification--coverage)
*   [Applications & Demos](#-applications--demos)

---

## ✨ Features

### Processor Core
*   **Architecture**: RISC-V 32-bit Integer Base (RV32I).
*   **Microarchitecture**: 5-Stage Pipeline (Fetch, Decode, Execute, Memory, Writeback).
*   **Hazel Management**: 
    *   **Forwarding Unit**: Resolves Data Hazards (RAW) to minimize stalls.
    *   **Stall Unit**: Handles Load-Use hazards and Control hazards.
*   **Memory**: Harvard Architecture (Separate Instruction and Data memory spaces).

### System & Simulation
*   **Memory-Mapped Output**: Video Memory (VRAM) mapped at `0x8000`.
*   **Simulation**:
    *   **Headless**: High-performance C++ simulation via Verilator for regression testing.
    *   **GUI**: Real-time SDL2-based visualization (640x480 resolution) for graphical applications.
*   **Verification**: 
    *   Regression suite including directed tests and random instruction generation.
    *   Hardware Coverage analysis using Verilator.

## 🏗 Architecture

The core relies on a comprehensive Verilog implementation located in `src/`.

**Pipeline Stages:**
1.  **IF (Instruction Fetch)**: PC update, Instruction Memory access.
2.  **ID (Instruction Decode)**: Register File read, Control Unit decoding, Immediate generation.
3.  **EX (Execute)**: ALU operations, Branch target calculation.
4.  **MEM (Memory)**: Data Memory access (Load/Store), MMIO (Video) writes.
5.  **WB (Writeback)**: Result write-back to Register File.

## 📂 Directory Structure

| Directory | Description |
|-----------|-------------|
| `app/`    | RISC-V Assembly applications and demos (Source & Hex). |
| `src/`    | Verilog source code for Core, Memory, and Peripherals. |
| `sim/`    | C++ Simulation wrappers (Headless, GUI, Coverage). |
| `tests/`  | Verification suite: Manual tests and Random Generator. |
| `build/`  | Compilation artifacts (Auto-generated). |
| `logs/`   | Simulation logs, coverage reports, and annotated source. |
| `runner.py`| Unified CLI tool for building, running, and testing. |

## 🚀 Quick Start (CLI)

The `runner.py` script manages the entire build and verification lifecycle.

### 1. Verification
Check system dependencies:
```bash
./runner.py check
```

### 2. Run Applications (GUI)
Run the provided demos to visualize processor activity:
```bash
# Colors Demo
./runner.py run --gui app/colors.s

# Audio Bars Visualization
./runner.py run --gui app/audio_bars.s
```

### 3. Run Regression Tests
Execute the full test suite (Manual + Random):
```bash
./runner.py test
```

### 4. Coverage Analysis
Generate a code coverage report to see which Verilog lines are executed:
```bash
./runner.py coverage
```
*Reports are saved to `logs/annotated/`.*

## 🧪 Verification & Coverage
The project uses a dual-verification strategy:
1.  **Directed Tests**: Specific assembly files (`tests/manual/`) checking corner cases (Hazards, Zero Register, etc.).
2.  **Random Testing**: `tests/test_gen.py` generates random instruction streams to stress-test the pipeline logic.

Use the `coverage` command to generate an annotated HTML-like report of the Verilog source, identifying untested logic paths.

## 🎮 Applications & Demos

| Application | Source | Description |
|-------------|--------|-------------|
| **Colors** | `app/colors.s` | Renders a full-screen color gradient, testing store operations and nested loops. |
| **Audio Bars** | `app/audio_bars.s` | Simulates a spectrum analyzer with decay physics. Originally ported from ARM Cortex M0. |

See [app/README.md](app/README.md) for more details.

## 📜 License
Open Source. Maintained by **Ismail Melik**.
