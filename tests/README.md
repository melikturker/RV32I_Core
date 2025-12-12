# RV32I Verification Suite

This directory contains the verification infrastructure for the RV32I Core. It uses a Python-based runner (`verify.py`) to manage random test generation, instruction loading, simulation execution, and result verification.

## Folder Structure

*   **`verify.py`**: The main test runner script.
*   **`riscv_model.py`**: A Golden Reference Model (Python) used to verify Register File states.
*   **`test_gen.py`**: Random instruction generator script.
*   **`test_histogram.py`**: Generator for the Histogram memory test application.
*   **`manual/`**: Directory for directed test files (Hex format).
    *   `01_Hazard_RAW.hex`: Read-After-Write Hazard Test.
    *   `02_Hazard_LoadUse.hex`: Load-Use Stall Hazard Test.
    *   `04_Corner_x0.hex`: x0 Write Protection Test.
    *   `05_Corner_StoreLoad.hex`: Memory Store-Load Forwarding Test.
*   **`results/`**: Output directory for test runs. Each run creates a timestamped folder (e.g., `Run_20251212_173000_QUICK`).

## How to Run Tests

### 1. Quick Mode (Sanity Check)
Runs 20 random instructions + All Directed Tests + Small Histogram.
```bash
python3 verify.py --mode quick
```

### 2. Standard Mode (Coverage)
Runs 100 random instructions + All Directed Tests + Standard Histogram.
```bash
python3 verify.py --mode standard
```

### 3. Stress Mode (Stability)
Runs 1000 random instructions + All Directed Tests + Large Histogram.
```bash
python3 verify.py --mode stress
```

## How It Works

1.  **Generation**: `verify.py` calls `test_gen.py` to create a random sequence of RISC-V instructions (`random_test_source.hex`) and a corresponding golden state (`expected_regs.txt`).
2.  **Compilation**: It invokes `make` in the root directory to compile the Verilog source.
3.  **Execution**: It runs the simulation (`vvp`), passing the test file dynamically via `+TESTFILE=...`.
4.  **Verification**: 
    *   **Registers**: Comparing the simulator's `reg_dump.txt` against the Python model's golden state.
    *   **Memory**: Comparing the simulator's `dmem_dump.txt` against the expected memory map (for Histogram tests).
5.  **Reporting**: Failing tests generate a `_failure.txt` file in the result directory with diff details.

## Adding New Tests

To add a new directed test:
1.  Create a hex file (machine code) in `tests/manual/`.
2.  Name it descriptively (e.g., `06_New_Feature.hex`).
3.  `verify.py` will automatically pick it up in the next run.
