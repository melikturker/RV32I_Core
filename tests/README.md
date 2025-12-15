# Verification Suite

This directory contains the verification infrastructure for the RV32I Core. The test suite combines directed manual tests with automated random instruction generation.

## Test Categories

### 1. Manual Tests (`tests/manual/`)
Targeted assembly/hex files designed to trigger specific hardware corner cases:
*   **01_Hazard_RAW**: Read-After-Write hazards (Data forwarding).
*   **02_Hazard_LoadUse**: Load-Use hazards (Stalling logic).
*   **03_Corner_x0**: Verifies that register `x0` remains constant (0).
*   **04_Corner_StoreLoad**: Memory store and load verification.

### 2. Random Instruction Test (`test_gen.py`)
A Python script that generates valid random RISC-V machine code streams.
*   **Generator**: `tests/test_gen.py`
*   **Output**: `build/random_test.hex`
*   **Coverage**: Generates R-type, I-type, U-type, Load, Store, and Branch instructions.

### 3. Default Sanity Check (`src/memory/instructions/instr.txt`)
A basic "alive" test that checks fetch-decode-execute-writeback pipeline integrity without complex hazards.
*   **Logic**: Loads immediates, stores to memory, and enters an infinite loop.
*   **Status**: Passes if the simulator executes the instruction stream without crashing.

## Running Tests

Tests are executed via the root runner CLI.

### Regression Testing
Runs the standard suite (Manual + 1000 Random Instructions):
```bash
./runner.py test
```

### Stress Testing
Runs a larger volume of random instructions to find rare edge cases:
```bash
# Generate 5000 random instructions
./runner.py test --count 5000 --seed 1234
```

## Coverage Analysis 📊
To measure which parts of the Verilog design are being exercised by tests, use the coverage tool. This requires `verilator` with coverage support enabled.

```bash
./runner.py coverage
```

**Workflow:**
1.  **Build**: Compiles the simulator with `--coverage` instrumentation.
2.  **Generate**: Creates a random test vector (default: 1000 instructions).
3.  **Simulate**: Runs the test to collect execution data.
4.  **Report**:
    *   Generates an Annotated Source Report in `logs/annotated/`.
    *   Prints a summary score to the terminal.

**Interpreting Results:**
*   Open `logs/annotated/VSoC_Core.v`.
*   Lines prefixed with a number (e.g., `1234: assign ...`) were executed 1234 times.
*   Lines prefixed with `%` or empty counts were **not executed** (Coverage Hole).
