import os
import sys
from test_gen import generate_i_type, generate_r_type, generate_s_type, generate_b_type, generate_j_type, to_hex_str

OUTPUT_DIR = "manual"
os.makedirs(OUTPUT_DIR, exist_ok=True)

def write_test(filename, instructions):
    filepath = os.path.join(OUTPUT_DIR, filename)
    with open(filepath, "w") as f:
        for inst in instructions:
            f.write(to_hex_str(inst) + "\n")
    print(f"Generated {filepath}")

def gen_RAW_Hazard():
    # Test Forwarding (EX->EX and MEM->EX)
    # 1. ADDI x1, x0, 10
    # 2. ADDI x2, x0, 20
    # 3. ADD x3, x1, x2  (Normal)
    # 4. ADD x4, x3, x1  (Hazard: x3 used immediately) -> Tests EX->EX Forwarding
    # 5. NOP
    # 6. NOP
    # 7. ADD x5, x3, x4  (No Hazard)
    
    insts = [
        generate_i_type(0x13, 1, 0, 0, 10),      # ADDI x1, x0, 10
        generate_i_type(0x13, 2, 0, 0, 20),      # ADDI x2, x0, 20
        generate_r_type(0x33, 3, 1, 2, 0, 0),    # ADD x3, x1, x2 = 30
        generate_r_type(0x33, 4, 3, 1, 0, 0),    # ADD x4, x3, x1 = 40 (Forwarding x3)
        0x00000013, 0x00000013,                  # NOPs
        generate_r_type(0x33, 5, 3, 4, 0, 0)     # ADD x5, x3, x4 = 70
    ]
    write_test("01_Hazard_RAW.hex", insts)

def gen_LoadUse_Hazard():
    # Test Load-Use Stall
    # 1. ADDI x10, x0, 100
    # 2. SW x10, 0(x0)     (M[0] = 100)
    # 3. LW x11, 0(x0)     (x11 = 100)
    # 4. ADD x12, x11, x10 (Hazard: x11 used immediately after Load) -> Should Stall
    
    insts = [
        generate_i_type(0x13, 10, 0, 0, 100),    # ADDI x10, x0, 100
        generate_s_type(0x23, 0, 10, 0),         # SW x10, 0(x0) -- funct3=2? test_gen defaults to 2
        generate_i_type(0x03, 11, 0, 2, 0),      # LW x11, 0(x0) (funct3=2 for LW)
        generate_r_type(0x33, 12, 11, 10, 0, 0), # ADD x12, x11, x10 = 200 (Stall needed)
        generate_i_type(0x13, 0, 0, 0, 0)        # NOP
    ]
    write_test("02_Hazard_LoadUse.hex", insts)

def gen_Branch_Flush():
    # Test Control Hazard Flush
    # 1. ADDI x1, x0, 5
    # 2. BEQ x1, x1, +8 (Skip next instruction)
    # 3. ADDI x5, x0, 99 (Should be FLUSHED/SKIPPED)
    # 4. ADDI x6, x0, 10 (Target)
    
    insts = [
        generate_i_type(0x13, 1, 0, 0, 5),       # ADDI x1, x0, 5
        generate_b_type(0x63, 1, 1, 0, 8),       # BEQ x1, x1, +8 (Offset=8)
        generate_i_type(0x13, 5, 0, 0, 99),      # ADDI x5, x0, 99 (BAD!)
        generate_i_type(0x13, 6, 0, 0, 10)       # ADDI x6, x0, 10 (Target)
    ]
    write_test("03_Hazard_Branch.hex", insts)

def gen_x0_Protection():
    # Test Write to x0
    # 1. ADDI x1, x0, 123
    # 2. ADD x0, x1, x1
    # 3. ADDI x2, x0, 0 -> x2 should be 0
    
    insts = [
        generate_i_type(0x13, 1, 0, 0, 123),     # ADDI x1, x0, 123
        generate_r_type(0x33, 0, 1, 1, 0, 0),    # ADD x0, x1, x1
        generate_i_type(0x13, 2, 0, 0, 0)        # ADDI x2, x0, 0 -> x2 should be 0
    ]
    write_test("04_Corner_x0.hex", insts)

def gen_StoreLoad_Forward():
    # Test Memory correctness
    # Store then immediate Load from same address
    insts = [
        generate_i_type(0x13, 1, 0, 0, 0xAA),    # ADDI x1, x0, 0xAA
        generate_s_type(0x23, 0, 1, 12),         # SW x1, 12(x0)
        generate_i_type(0x03, 2, 0, 2, 12),      # LW x2, 12(x0) -> x2 = 0xAA
    ]
    write_test("05_Corner_StoreLoad.hex", insts)

if __name__ == "__main__":
    print("Generating Directed Tests...")
    gen_RAW_Hazard()
    gen_LoadUse_Hazard()
    gen_Branch_Flush()
    gen_x0_Protection()
    gen_StoreLoad_Forward()
    print("Done.")
