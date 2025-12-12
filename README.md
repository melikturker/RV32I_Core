# RV32I Processor Core

A synthesizable, 5-stage pipelined RISC-V 32I Processor Core written in Verilog.
## Verification / Testing 🧪
This project includes a comprehensive Python-based verification suite located in the `tests/` directory.

### Prerequisites
*   Python 3
*   Icarus Verilog

### How to Run Tests
The repository features an advanced automated verification suite. For detailed instructions, please see [tests/README.md](tests/README.md).

Quick Usage:
```bash
cd tests
python3 verify.py --mode quick
```
This runs a rapid sanity check including randomized instructions, pipeline hazard corner cases (Load-Use, Branch Flush, etc.), and a memory histogram application.

Also available:
*   `--mode standard`: Broader coverage (100 random instr).
*   `--mode stress`: Long-duration stability check (1000 instr).

## Features
- **ISA:** RISC-V RV32I (Base Integer Instruction Set)
- **Pipeline:** 5-Stage (Fetch, Decode, Execute, Memory, Writeback)
- **Hazard Handling:** Full Forwarding Unit (EX-EX, MEM-EX) and Load-Use Stall Unit
- **Memory:** Separate Instruction (4KB) and Data interaction (4KB)
- **Simulation:** Icarus Verilog compatible

## Directory Structure
- `src/`: Verilog source code (`Core.v`, `ALU.v`, `CU.v`, etc.)
- `tb/`: Testbench files (`tb.v`)
- `instructions/`: Hex firmware files (`instr.txt`)
- `Makefile`: Build automation script

## Quick Start

### Prerequisites
- **Icarus Verilog:** `sudo apt install iverilog`
- **GTKWave:** `sudo apt install gtkwave`

### Simulation
You can use the provided `Makefile` for easy compilation and simulation.

1.  **Run Simulation:**
    ```bash
    make run
    ```
    This compiles the design and runs the testbench.

2.  **View Waveforms:**
    ```bash
    make wave
    ```
    This opens GTKWave with the saved signal configuration (`waves.gtkw`).

### Manual Compilation
If you prefer running commands manually:

```bash
# Compile
iverilog -o a.out src/*.v tb/tb.v

# Run
vvp a.out

# View
gtkwave tb.vcd
```

## Custom Programs
To run your own assembly code:
1.  Convert your RISC-V assembly to machine code (hex).
2.  Paste the hex values into `instructions/instr.txt`.
3.  Run `make run` again.
