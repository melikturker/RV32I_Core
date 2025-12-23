# RV32I Core

![License](https://img.shields.io/badge/license-MIT-blue.svg)
![Verilog](https://img.shields.io/badge/verilog-2005-green.svg)
![Simulation](https://img.shields.io/badge/simulation-verilator-orange.svg)

## 📖 Overview

**RV32I Core** is a cycle-accurate, 5-stage pipelined RISC-V processor implementation written in Verilog. It implements the complete **RV32I Base Integer Instruction Set** and is designed for education, simulation, and experimentation.

Key highlights:
*   **5-Stage Pipeline:** Classic Fetch, Decode, Execute, Memory, Writeback architecture.
*   **Hazard Management:** Full checking for RAW hazards (Forwarding/Stalling) and Control hazards (Branch Prediction/Flushing).
*   **Visual Simulation:** Includes a custom **SDL2-based GUI** for real-time visualization of the VRAM (320x240 32-bit Color).
*   **Robust Verification:** Comprehensive suite of functional tests, random instruction labeling, and performance benchmarks.

This project serves as a clean reference implementation for understanding processor microarchitecture and pipeline controls.

<p align="center">
  <img src="docs/videos/audio_bars.gif" width="45%" />
  <img src="docs/videos/bouncing_square.gif" width="45%" />
</p>

## 📌 Navigation
*   [Features](#-features)
*   [Architecture](#-architecture)
*   [Directory Structure](#-directory-structure)
*   [Quick Start](#-quick-start-cli)
*   [Verification & Coverage](#-verification--coverage)
*   [Applications & Demos](#-applications--demos)
*   [Documentation](#-documentation)

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
    *   **Performance regression testing** with automated baseline comparison.
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
| `app/`    | RISC-V Assembly applications and demos (colors, audio, graphics). |
| `src/`    | Verilog source code for Core, Memory, and Peripherals. |
| `sim/`    | C++ Simulation wrappers (Headless, GUI, Coverage). |
| `tb/`     | Testbench files for Verilog simulation. |
| `tests/`  | Test suite: Functional tests and Performance benchmarks. |
| `docs/`   | Documentation (Architecture, Metrics, guides). |
| `tools/`  | [Python utilities](tools/README.md) (assembler, performance analysis, test generation). |
| `build/`* | Compilation artifacts (Auto-generated, not in repo). |
| `logs/`*  | Simulation logs, coverage reports, and annotated source (Auto-generated). |
| `runner.py`| Unified CLI tool for build, run, test, and coverage. |

*\*Auto-generated directories created during build/test runs.*

## 🚀 Quick Start (CLI)

The `runner.py` script manages the entire build and verification lifecycle.

### 1. Check Dependencies
Verify all system dependencies are installed:
```bash
./runner.py env
```

### 2. Run Applications
Run the provided demos to visualize processor activity (GUI auto-launches if VRAM is used):
```bash
# Colors Demo
./runner.py run app/colors.s

# Audio Bars Visualization
./runner.py run app/audio_bars.s
```

### 3. Run Tests

Execute the full test suite (Functional + Performance):
```bash
./runner.py test
```

Run only functional tests (hazards, corner cases, ISA coverage):
```bash
./runner.py test --functional
```

Run only performance benchmarks:
```bash
./runner.py test --performance
```

### 4. Performance Benchmarking

Run performance benchmarks with detailed analysis:
```bash
# Run all benchmarks
./runner.py test --performance

# Show detailed per-benchmark reports
./runner.py test --performance --verbose

# Save summary to file
./runner.py test --performance --save
```

### 5. Regression Testing

Check for performance regressions against baseline:
```bash
# Save current performance as baseline
./runner.py test --performance --save-baseline

# Check for regressions
./runner.py test --performance --check-regression
```

### 6. Coverage Analysis
Generate a code coverage report to see which Verilog lines are executed:
```bash
./runner.py coverage
```
*Reports are saved to `logs/annotated/`.*

## 🧪 Verification & Coverage
The project uses a dual-verification strategy:
1.  **Directed Tests**: Specific assembly files (`tests/functional/`) checking corner cases (Hazards, Zero Register, etc.).
2.  **Random Testing**: `tools/random_instruction_test_gen.py` generates random instruction streams to stress-test the pipeline logic.

Use the `coverage` command to generate an annotated HTML-like report of the Verilog source, identifying untested logic paths.

## 🎮 Applications & Demos

| Application | Source | Description |
|-------------|--------|-------------|
| **Colors** | `app/colors.s` | Cycles through full-screen colors (R/G/B), verifying VRAM write performance. |
| **XOR Patterns** | `app/xor_patterns.s` | Generates fractal textures using bitwise XOR/OR logic on coordinates. |
| **Dream** | `app/dream.s` | Advanced plasma animation with independent RGB flow and alpha fluctuation. |
| **Audio Bars** | `app/audio_bars.s` | Spectrum analyzer simulation with pseudorandomly changing heights and colors. |
| **Bouncing Square** | `app/bouncing_square.s` | Configurable square (25px) that changes color on bounce and paints trails. |

### 🖼️ Visual Gallery

| Colors | XOR Patterns |
| :---: | :---: |
| ![Colors](docs/videos/colors.gif) | ![XOR](docs/videos/xor_patterns.gif) |

| Dream (Showcase) | Audio Bars |
| :---: | :---: |
| ![Dream](docs/videos/dream.gif) | ![Audio](docs/videos/audio_bars.gif) |

| Bouncing Square | |
| :---: | :---: |
| ![Square](docs/videos/bouncing_square.gif) | |

See [app/README.md](app/README.md) for more details.

## 📚 Documentation

*   **[Architecture Guide](docs/ARCHITECTURE.md)** - Pipeline stages, hazard handling, memory system
*   **[Metrics Reference](docs/METRICS.md)** - Explanation of all performance metrics
*   **[Performance Benchmarks](tests/performance/README.md)** - Benchmark suite and regression testing
*   **[Applications](app/README.md)** - Demo applications and visual examples


## 📜 License
This project is licensed under the **MIT License**. See [LICENSE](LICENSE) for details.

Maintained by **Ismail Melik**.
