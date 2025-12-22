# RV32I Core Architecture

## 📌 Navigation
*   [Return to Main README](../README.md)
*   [Metrics Reference](METRICS.md)
*   [Pipeline Stages](#pipeline-stages)
*   [Hazard Management](#hazard-management)
*   [Memory System](#memory-system)

---

## Overview

The RV32I core utilizes a **classic 5-stage pipeline** microarchitecture (Fetch, Decode, Execute, Memory, Writeback). It is designed to execute the RISC-V 32-bit Integer Base (RV32I) instruction set with full hazard detection and forwarding capabilities.

---

## Pipeline Stages

### 1. IF (Instruction Fetch)
**Module:** `Fetch_Stage.v`

**Responsibilities:**
- Program Counter (PC) update
- Instruction Memory access
- Next PC calculation (PC+4 or branch target)

**Outputs:**
- Current instruction
- PC value (for branch/jump calculations)

---

### 2. ID (Instruction Decode)
**Module:** `Decode_Stage.v`

**Responsibilities:**
- Control signal generation
- Register File read (rs1, rs2)
- Immediate value extraction and sign-extension
- Operand forwarding detection

**Key Components:**
- Control Unit
- Register File (32 x 32-bit registers)
- Immediate Generator

**Outputs:**
- Decoded control signals
- Register operands (rs1_data, rs2_data)
- Immediate value

---

### 3. EX (Execute)
**Module:** `Execute_Stage.v`

**Responsibilities:**
- ALU operations
- Branch condition evaluation
- Branch/jump target address calculation
- Forwarding path selection

**Key Components:**
- ALU (Arithmetic Logic Unit)
- Branch Comparator
- Forwarding Multiplexers

**Outputs:**
- ALU result
- Branch taken/not taken signal
- Target address (for branches/jumps)

---

### 4. MEM (Memory Access)
**Module:** `Memory_Stage.v`

**Responsibilities:**
- Data Memory access (loads/stores)
- Memory-mapped I/O (VRAM writes at 0x8000)
- Load data formatting (byte/half/word)

**Key Components:**
- Data Memory (Main_Memory.v)
- Video Memory (VRAM) interface

**Outputs:**
- Load data (from memory)
- Passthrough of ALU result (for non-memory ops)

---

### 5. WB (Writeback)
**Module:** `Writeback_Stage.v`

**Responsibilities:**
- Result selection (ALU result vs Load data)
- Register File write

**Outputs:**
- Final result written to destination register

---

## Hazard Management

### Data Hazards (Read-After-Write)

**Problem:** Instruction needs data from previous instruction before it's written back.

**Solutions:**

#### 1. Data Forwarding
**Module:** `Forwarding_Unit.v`

Forwards data directly from EX/MEM or MEM/WB stages to EX stage inputs, bypassing the register file.

**Forwarding Paths:**
- EX → EX (ALU result to next instruction)
- MEM → EX (Load result or passthrough)

**Coverage:** Resolves most RAW hazards without stalling.

#### 2. Pipeline Stalls
**Module:** `Stall_Unit.v`

Stalls the pipeline when forwarding cannot resolve the hazard (load-use case).

**Load-Use Hazard:**
- Load instruction in EX stage
- Next instruction needs loaded data
- Must stall for 1 cycle to wait for load completion

---

### Control Hazards (Branches/Jumps)

**Problem:** Branch/jump target not known until EX stage, but IF has already fetched next instruction.

**Solution:** Pipeline Flush

**Strategy:**
- Static "not taken" prediction (assume branches not taken)
- If branch actually taken → flush IF and ID stages
- Jump instructions (JAL/JALR) always flush

**Performance Impact:**
- 2-cycle penalty for taken branches
- Backward branches (loops) always taken → always flushed

---

## Memory System

### Harvard Architecture
Separate instruction and data memory spaces for parallel access.

**Instruction Memory:**
- Read-only during execution
- Loaded from .hex file at simulation start
- Size: Configurable (default 64KB)

**Data Memory:**
- Read/write during execution
- Byte-addressable
- Size: Configurable (default 64KB)

### Memory-Mapped I/O

**VRAM (Video Memory):**
- Base address: `0x8000`
- Resolution: 320×240 pixels
- Format: 32-bit ARGB (4 bytes per pixel)
- Interface: SDL2 rendering (scaled 2x to 640×480 window)

**Store Operations:**
- Addresses < 0x8000 → Data Memory
- Addresses ≥ 0x8000 → VRAM

---

## Register File

**Specification:**
- 32 general-purpose registers (x0-x31)
- 32-bit width per register
- x0 hardwired to zero
- 2 read ports, 1 write port

**Special Registers:**
- x0: Always zero (writes ignored)
- x1 (ra): Return address (convention)
- x2 (sp): Stack pointer (convention)

---

## Performance Monitoring

The core includes comprehensive performance counters:

**Cycle Counters:**
- Total cycles
- Stall cycles
- Bubble cycles
- Flush cycles

**Instruction Counters:**
- Instructions retired
- By type: ALU-R, ALU-I, Load, Store, Branch, Jump

**Hazard Counters:**
- RAW hazards detected
- Forwards executed
- Stalls incurred

**Control Flow:**
- Conditional branches
- Unconditional jumps
- Flushes (mispredictions)

See [METRICS.md](METRICS.md) for detailed metric definitions.

---

## Pipeline Control Signals

**Key Control Signals:**

| Signal | Purpose |
|--------|---------|
| `RegWrite` | Enable register file write |
| `MemRead` | Enable data memory read |
| `MemWrite` | Enable data memory write |
| `ALUSrc` | ALU operand source (register/immediate) |
| `MemtoReg` | Writeback source (ALU/memory) |
| `Branch` | Conditional branch instruction |
| `Jump` | Unconditional jump instruction |
| `ALUOp` | ALU operation code |

**Pipeline Registers:**
- IF/ID: Instruction, PC
- ID/EX: Control signals, operands, PC
- EX/MEM: ALU result, control signals, operands
- MEM/WB: Result, control signals

---

## Simulation Modes

### Headless Mode
**Build target:** `headless`

- Fast cycle-accurate simulation
- No graphical output
- Used for regression testing
- Verilator C++ compilation

### GUI Mode
**Build target:** `gui`

- Real-time SDL2 visualization
- VRAM (320x240) scaled to 640×480 window
- ~60 FPS target
- Automatic mode selection if VRAM used

### Coverage Mode
**Build target:** `coverage`

- Verilator coverage instrumentation
- Generates coverage.dat
- Annotated source reports
- Line and toggle coverage

---

## Testing & Verification

**Test Categories:**
1. **Functionality Tests** - Correctness validation
2. **Performance Benchmarks** - Performance characterization
3. **Random Tests** - Stress testing with random instruction streams

See [Performance Benchmarks](../tests/performance/README.md) for details.

---

## Related Documentation

- **[Metrics Reference](METRICS.md)** - Performance metric definitions
- **[Performance Benchmarks](../tests/performance/README.md)** - Benchmark suite guide
- **[Main README](../README.md)** - Project overview

---

## Implementation Files

**Core Pipeline:**
- `src/Fetch_Stage.v`
- `src/Decode_Stage.v`
- `src/Execute_Stage.v`
- `src/Memory_Stage.v`
- `src/Writeback_Stage.v`

**Hazard Management:**
- `src/Forwarding_Unit.v`
- `src/Stall_Unit.v`

**Memory:**
- `src/memory/Main_Memory.v`
- `src/memory/VRAM.v`

**Top-Level:**
- `src/RV32I_Core.v`
