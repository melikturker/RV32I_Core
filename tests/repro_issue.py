import os
import subprocess

def generate_i_type(opcode, rd, rs1, funct3, imm):
    inst = (imm & 0xFFF) << 20 | (rs1 & 0x1F) << 15 | (funct3 & 0x7) << 12 | (rd & 0x1F) << 7 | (opcode & 0x7F)
    return inst

def generate_s_type(opcode, rs1, rs2, imm):
    imm11_5 = (imm >> 5) & 0x7F
    imm4_0 = imm & 0x1F
    funct3 = 0x2
    inst = (imm11_5) << 25 | (rs2 & 0x1F) << 20 | (rs1 & 0x1F) << 15 | (funct3 & 0x7) << 12 | (imm4_0) << 7 | (opcode & 0x7F)
    return inst

def generate_j_type(opcode, rd, imm):
    imm20 = (imm >> 20) & 0x1
    imm10_1 = (imm >> 1) & 0x3FF
    imm11 = (imm >> 11) & 0x1
    imm19_12 = (imm >> 12) & 0xFF
    inst = (imm20 << 31) | (imm19_12 << 12) | (imm11 << 20) | (imm10_1 << 21) | (rd & 0x1F) << 7 | (opcode & 0x7F)
    return inst

def generate_b_type(opcode, rs1, rs2, funct3, imm):
    # imm[12|10:5] [4:1|11]
    imm12 = (imm >> 12) & 0x1
    imm10_5 = (imm >> 5) & 0x3F
    imm4_1 = (imm >> 1) & 0xF
    imm11 = (imm >> 11) & 0x1
    inst = (imm12 << 31) | (imm10_5 << 25) | (rs2 & 0x1F) << 20 | (rs1 & 0x1F) << 15 | (funct3 & 0x7) << 12 | (imm4_1 << 8) | (imm11 << 7) | (opcode & 0x7F)
    return inst

instructions = []
def add(inst): instructions.append(inst)

# -----------------------------------------------------
# MINIMAL FAILURE REPRODUCTION
# Scenario: "Odd -> JAL -> Neg" path
# -----------------------------------------------------

# 1. SETUP
# x3 = Base Address (0)
add(generate_i_type(0x13, 3, 0, 0, 0)) # ADDI x3, x0, 0
# Initialize x4 = -87
add(generate_i_type(0x13, 4, 0, 0, -87)) # ADDI x4, x0, -87

# Initialize M[16] (Counter) = 0
add(generate_i_type(0x13, 8, 0, 0, 0)) # ADDI x8, x0, 0
add(generate_s_type(0x23, 3, 8, 16))   # SW x8, 16(x0)

# 2. TRIGGER SEQUENCE
# Mimic "Odd" block finishing
add(generate_i_type(0x13, 8, 0, 0, 99)) # ADDI x8, x0, 99 (Dirty x8)

# JAL to Join (Skip 2 intrs)
add(generate_j_type(0x6F, 0, 12))      # JAL x0, +12

# Skipped Block
add(generate_i_type(0x13, 8, 0, 0, 55))
add(generate_i_type(0x13, 8, 0, 0, 55))

# Join: NEG Check
# BGE x4, x0, SKIP_NEG (+16 bytes = 4 instrs)
# If x4 (-87) < 0, branch NOT taken. Execute Neg.
add(generate_b_type(0x63, 4, 0, 5, 16)) # BGE x4, x0, +16

# Neg Block
add(generate_i_type(0x03, 8, 0, 2, 16)) # LW x8, 16(x0)
add(generate_i_type(0x13, 8, 8, 0, 1))  # ADDI x8, x8, 1
add(generate_s_type(0x23, 0, 8, 16))   # SW x8, 16(x0)

# SKIP_NEG
add(0x00000013) # NOP

# End
add(0x00000013) # NOP
add(0x00000013) # NOP
add(0x00000013) # NOP

# -----------------------------------------------------
# OUTPUT
# -----------------------------------------------------
with open("repro.hex", "w") as f:
    for inst in instructions:
        f.write(f"{inst & 0xFFFFFFFF:08x}\n")

print("Generated repro.hex with 10 instructions.")

# Run Simulation
# 1. Copy hex
subprocess.call("cp repro.hex ../instructions/instr.txt", shell=True)
# 2. Run
print("Running simulation...")
subprocess.call("make -C .. run > repro_log.txt 2>&1", shell=True)
# 3. Check Result
print("\nChecking Memory Dump (M[16]):")
# Index 16 >> 2 = 4. Memory[4].
# dump file format: M[16]: val
try:
    with open("../dmem_dump.txt", "r") as f:
        for line in f:
            if "M[16]:" in line:
                print(line.strip())
                val = line.split(":")[1].strip()
                if val == "00000001":
                    print("PASS: Counter incremented to 1")
                elif "x" in val:
                    print("FAIL: Propagated X!")
                else:
                    print(f"FAIL: Unexpected value {val}")
except FileNotFoundError:
    print("Error: dmem_dump.txt not found")
