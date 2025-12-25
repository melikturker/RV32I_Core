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

---

## VCD Analyzer

### vcd_analyzer.py
**Purpose:** Generate text-based analysis from VCD waveform files

**Usage via runner.py** (recommended):
```bash
./runner.py run test.s --trace --analyze=MODE
```

**Standalone usage**:
```bash
python3 vcd_analyzer.py input.vcd output_dir/
```

**Output:** `logs/traces/test_TIMESTAMP/` with 5 trace types:

---

### Analysis Modes

#### `--analyze=all` (Full Analysis)
Generates all 5 trace files:
- **exec.txt**: Execution trace (PC + instruction flow)
- **pipeline.txt**: Pipeline stage visualization (IF/ID/EX/MEM/WB)
- **events.txt**: Branch/hazard/system events
- **state.txt**: Final signal states
- **report.txt**: Summary + auto-bug detection

**Use case:** Comprehensive debugging session

#### `--analyze=minimal` (Quick Check)
Generates:
- **exec.txt**: PC + instruction disassembly
- **pipeline.txt**: 5-stage PC propagation

**Use case:** Quick execution flow check

#### `--analyze=debug` (Bug Hunting)
Generates:
- **pipeline.txt**: Stage-by-stage visualization
- **events.txt**: Critical events (branches, flushes)
- **report.txt**: Auto-detected issues ⚠️

**Use case:** Debugging pipeline bugs, flush timing issues

#### `--analyze=exec,pipeline,events` (Custom)
Comma-separated list of desired trace types.

**Use case:** Pick exactly what you need

---

### Trace Type Details

#### 1. Execution Trace (`exec.txt`)
PC-level instruction flow with disassembly:
```
Cycle    | PC         | Hex        | Disassembly
---------|------------|------------|---------------------------
6        | 0x00000014 | 0x00100073 | ebreak
7        | 0x00000008 | 0x00000013 | addi x0, x0, 0
```
**Usage:** Track program flow, verify instruction sequence

#### 2. Pipeline Trace (`pipeline.txt`)
Hybrid format showing all 5 stages + control signals:
```
Cycle  | IF_PC    ID_PC    EX_PC    MEM_PC   WB_PC    | EX_op  Flush Stall
-------|----------------------------------------------|---------------------
6      | 00000014 00000010 0000000c 00000008 00000004 | 0x63   1     0
```
**Usage:** Visualize pipeline propagation, spot flush/stall issues

#### 3. Events Trace (`events.txt`)
Categorized events (branch/hazard/system):
```
=== BRANCH EVENTS ===
Cycle  | PC         | Taken | Flush
-------|------------|-------|-------
6      | 0x0000000c | YES   | 1

=== SYSTEM EVENTS ===
Cycle  | Event           | PC
-------|-----------------|----------
9      | EBREAK/ECALL    | 0x00000000
```
**Usage:** Branch prediction analysis, event tracking

#### 4. Final State (`state.txt`)
All signal values at last cycle:
```
=== AVAILABLE SIGNALS (Final Cycle) ===
PC_IF                = 0x00000010 (16)
opcode_WB            = 0x00000073 (115)
flush                = 0x00000000 (0)
```
**Usage:** Final state verification, signal inspection

#### 5. Debug Report (`report.txt`)
**Auto-bug detection** + execution summary:
```
=== EXECUTION SUMMARY ===
Total Cycles: 10
Branch Instructions: 1
Pipeline Flushes: 2

=== CRITICAL ISSUES DETECTED ===
⚠️  [Cycle 7] Flush timing bug: EBREAK (0x73) in EX despite flush=1
```
**Usage:** Automatic bug spotting, quick issue overview

---

### Example Workflows

**Scenario 1: Loop not working**
```bash
./runner.py run loop.s --trace --analyze=debug
# Check: events.txt (branch taken/not-taken)
# Check: report.txt (auto-detected issues)
```

**Scenario 2: Quick execution check**
```bash
./runner.py run test.s --trace --analyze=minimal
# Check: exec.txt (instruction flow)
```

**Scenario 3: Pipeline hazard analysis**
```bash
./runner.py run hazard_test.s --trace --analyze=pipeline,events
# Check: pipeline.txt (stalls/forwards)
# Check: events.txt (hazard events)
```

---

### Output Location

All traces go to: `logs/traces/TEST_TIMESTAMP/`

**Example:**
```
logs/
├── waveforms/
│   └── counter_loop_20251225_160237.vcd
└── traces/
    └── counter_loop_20251225_160237/  ← Matches VCD timestamp!
        ├── exec.txt
        ├── pipeline.txt
        ├── events.txt
        ├── state.txt
        └── report.txt
```

**Cleanup:** `rm -rf logs/traces/*` to remove old traces

