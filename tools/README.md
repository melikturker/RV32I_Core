# Helper Tools

This directory contains Python scripts used by `runner.py` for build, test, and analysis tasks.

Most users should interact with these via `runner.py`, but they can be used standalone for debugging.

---

## Core Tools

### assembler.py
**Usage:** `python3 assembler.py input.s output.hex`
- Converts RISC-V assembly (`.s`) to machine code (`.hex`).
- Handles label resolution and pseudo-instructions.
- Generates hex format compatible with Verilog `$readmemh`.

### random_instruction_test_gen.py
**Usage:** `python3 random_instruction_test_gen.py --out test.hex --count 100`
- Generates valid random RISC-V instruction streams.
- Avoids infinite loops (backward branches limited).
- Ensures register usage validity (e.g., x0 always 0).
- Used for stress testing the pipeline.

---

## Performance Analysis Tools

### performance_summary.py
**Usage:** (Internal, called by runner.py)
- Parses `logs/perf_counters.txt`.
- Generates the summary tables shown in `runner.py test --performance`.
- Handles metrics calculation (IPC, stall rates, etc.).

### regression_checker.py
**Usage:** (Internal)
- Compares current performance metrics against `tests/performance/expected.json`.
- Calculates deltas (absolute and relative).
- Determines PASS/FAIL status based on tolerances.

### performance_report.py
**Usage:** (Internal)
- Generates detailed per-benchmark reports (used with `--verbose`).
- Prints instruction mix and hazard details.

---

## Verification Tools

### isa_full_coverage_gen.py
**Usage:** `python3 isa_full_coverage_gen.py`
- Generates a test suite covering all RISC-V 32I instructions.
- Used to verify complete ISA support and decode logic.

