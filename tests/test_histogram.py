import random
from riscv_model import RISCV_Model

def to_hex_str(val, bits=32):
    return f"{val & ((1<<bits)-1):0{bits//4}x}"

def generate_i_type(opcode, rd, rs1, funct3, imm):
    inst = (imm & 0xFFF) << 20 | (rs1 & 0x1F) << 15 | (funct3 & 0x7) << 12 | (rd & 0x1F) << 7 | (opcode & 0x7F)
    return inst

def generate_r_type(opcode, rd, rs1, rs2, funct3, funct7):
    inst = (funct7 & 0x7F) << 25 | (rs2 & 0x1F) << 20 | (rs1 & 0x1F) << 15 | (funct3 & 0x7) << 12 | (rd & 0x1F) << 7 | (opcode & 0x7F)
    return inst

def generate_s_type(opcode, rs1, rs2, imm):
    imm11_5 = (imm >> 5) & 0x7F
    imm4_0 = imm & 0x1F
    funct3 = 0x2 # SW
    inst = (imm11_5) << 25 | (rs2 & 0x1F) << 20 | (rs1 & 0x1F) << 15 | (funct3 & 0x7) << 12 | (imm4_0) << 7 | (opcode & 0x7F)
    return inst

def generate_b_type(opcode, rs1, rs2, funct3, imm):
    imm12 = (imm >> 12) & 0x1
    imm10_5 = (imm >> 5) & 0x3F
    imm4_1 = (imm >> 1) & 0xF
    imm11 = (imm >> 11) & 0x1
    inst = (imm12 << 31) | (imm10_5 << 25) | (rs2 & 0x1F) << 20 | (rs1 & 0x1F) << 15 | (funct3 & 0x7) << 12 | (imm4_1 << 8) | (imm11 << 7) | (opcode & 0x7F)
    return inst

def generate_j_type(opcode, rd, imm):
    inst = (imm & 0x80000) << 11 | (imm & 0x3FF) << 21 | (imm & 0x400) << 10 | (imm & 0xFF000) | (rd & 0x1F) << 7 | (opcode & 0x7F)
    # Correct J-Type encoding:
    # imm[20|10:1|11|19:12] | rd | opcode
    imm20 = (imm >> 20) & 0x1
    imm10_1 = (imm >> 1) & 0x3FF
    imm11 = (imm >> 11) & 0x1
    imm19_12 = (imm >> 12) & 0xFF
    inst = (imm20 << 31) | (imm19_12 << 12) | (imm11 << 20) | (imm10_1 << 21) | (rd & 0x1F) << 7 | (opcode & 0x7F)
    return inst

def main():
    import argparse
    parser = argparse.ArgumentParser(description="Generate Histogram Test")
    parser.add_argument("--count", type=int, default=10, help="Number of inputs")
    parser.add_argument("--seed", type=int, default=None, help="Random seed")
    parser.add_argument("--range", nargs=2, type=int, default=[-100, 100], help="Min Max value range")
    parser.add_argument("--out", type=str, default="histogram_test.txt", help="Output hex file")
    parser.add_argument("--mem", type=str, default="expected_dmem.txt", help="Expected memory file")
    
    args = parser.parse_args()
    
    if args.seed is not None:
        random.seed(args.seed)
        
    print(f"Generating Histogram Test: Count={args.count}, Range={args.range}, Seed={args.seed}")
    
    instructions = []
    
    # ---------------------------------------------------------
    # 1. SETUP & INITIALIZATION
    # ---------------------------------------------------------
    
    inputs = []
    for _ in range(args.count): 
        val = random.randint(args.range[0], args.range[1])
        inputs.append(val)
        
    threshold = 10
    
    # Python Expected Calculation
    exp_odd = 0
    exp_even = 0
    exp_neg = 0
    exp_pow2 = 0
    exp_mod4 = 0
    exp_thresh = 0
    
    for x in inputs:
        if x & 1: exp_odd += 1
        else: exp_even += 1
        
        if x < 0: exp_neg += 1
        
        if x > 0 and (x & (x-1) == 0):
            exp_pow2 += 1
            
        if (x & 3) == 0: # Modulo 4
            exp_mod4 += 1
            
        if x < threshold:
            exp_thresh += 1

    print(f"Inputs: {inputs}")
    print(f"Expected -> Odd:{exp_odd}, Even:{exp_even}, Neg:{exp_neg}, Pow2:{exp_pow2}, Mod4:{exp_mod4}, <{threshold}:{exp_thresh}")

    # ---------------------------------------------------------
    # 2. ASSEMBLY GENERATION
    # ---------------------------------------------------------
    
    # Helper to add instruction
    def add(inst): instructions.append(inst)
    
    # A. Initialize Inputs in Memory 
    add(generate_i_type(0x13, 3, 0, 0, 0)) # ADDI x3, x0, 0 (Base Address)
    
    for idx, val in enumerate(inputs):
        # Load value into x4 (Handle large immediates if needed? Range is restricted for now)
        add(generate_i_type(0x13, 4, 0, 0, val)) # ADDI x4, x0, val
        # Store to Memory
        add(generate_s_type(0x23, 3, 4, idx*4)) # SW x4, idx*4(x3)
        
    # Old initialization block removed

    
    # Offsets in WORDS relative to Counter Base
    # 0, 1, 2, 3, 4 -> 0, 4, 8, 12, 16 bytes
    # Actually, let's just initialize using absolute addresses in loop or just rely on loop
    # Original code: for i in range(20, 27): SW x4, i(x0).
    # New code: We need valid addresses.
    # Let's set Counter Base Register x7 first? 
    # But initialization happens before loop.
    
    # Let's use x7 for counters. 
    # Inputs take len(inputs)*4 bytes.
    input_size = len(inputs) * 4
    counter_base = input_size + 16 # Padding
    
    # Initialize Counters (0 to 4 inclusive = 5 counters) relative to x0
    # Use absolute addresses
    add(generate_i_type(0x13, 4, 0, 0, 0)) # ADDI x4, x0, 0 (Clear x4)
    
    for i in range(5):
        addr = counter_base + i*4
        add(generate_s_type(0x23, 0, 4, addr)) # SW x4, addr(x0)
        
    c_odd = counter_base + 0
    c_even = counter_base + 4
    c_mod4 = counter_base + 8  # Swapped with c_neg
    c_neg = counter_base + 12 # Swapped with c_mod4
    c_thresh = counter_base + 16

    # C. Main Loop Setup
    add(generate_i_type(0x13, 1, 0, 0, 0))   # ADDI x1, x0, 0 (i = 0)
    add(generate_i_type(0x13, 2, 0, 0, len(inputs)))  # ADDI x2, x0, len(inputs) (Limit)
    add(generate_i_type(0x13, 3, 0, 0, 0))   # ADDI x3, x0, 0 (Input Pointer)
    # x7 is removed
    add(generate_i_type(0x13, 9, 0, 0, threshold)) # ADDI x9, x0, threshold
    add(generate_i_type(0x13, 10, 0, 0, 1))  # ADDI x10, x0, 1 (Const 1)

    # LOOP START
    loop_start_idx = len(instructions)
    loop_check_idx = loop_start_idx # Placeholder
    add(0) # BGE check patch
    
    # Load Input: LW x4, 0(x3)
    add(generate_i_type(0x03, 4, 3, 2, 0)) 
    
    # --- CLASSIFICATION START ---
    
    # 1. Odd/Even
    # ANDI x5, x4, 1
    add(generate_i_type(0x13, 5, 4, 7, 1))
    
    branch_even_idx = len(instructions)
    add(0) # BEQ x5, x0, is_even

    # ODD CASE
    # LW x8, c_odd(x0) -> ADDI x8, x8, 1 -> SW x8, c_odd(x0)
    add(generate_i_type(0x03, 8, 0, 2, c_odd))
    add(generate_i_type(0x13, 8, 8, 0, 1))
    add(generate_s_type(0x23, 0, 8, c_odd))
    
    # Jump to check 2
    branch_join_1 = len(instructions)
    add(0) # JAL x0, skip_even

    # EVEN CASE
    # Backpatch branch_even_idx -> Offset to here
    offset_even = (len(instructions) - branch_even_idx) * 4
    instructions[branch_even_idx] = generate_b_type(0x63, 5, 0, 0, offset_even) # BEQ
    
    add(generate_i_type(0x03, 8, 0, 2, c_even))
    add(generate_i_type(0x13, 8, 8, 0, 1))
    add(generate_s_type(0x23, 0, 8, c_even))
    
    # Join
    offset_join1 = (len(instructions) - branch_join_1) * 4
    instructions[branch_join_1] = generate_j_type(0x6F, 0, offset_join1)
    
    # 4. Check Negative (x4 < 0)
    # BLT x4, x0, is_neg (Assuming signed) -> BGE x4, x0, skip_neg
    branch_pos_idx = len(instructions)
    add(0) 
    
    # NEG CASE
    add(generate_i_type(0x03, 8, 0, 2, c_neg))
    add(generate_i_type(0x13, 8, 8, 0, 1))
    add(generate_s_type(0x23, 0, 8, c_neg))
    
    # SKIP NEG
    instructions[branch_pos_idx] = generate_b_type(0x63, 4, 0, 5, (len(instructions)-branch_pos_idx)*4) # BGE x4, x0
    
    # 5. Check Mod 4 (ANDI x5, x4, 3)
    add(generate_i_type(0x13, 5, 4, 7, 3))
    branch_mod4_idx = len(instructions)
    add(0) # BNE
    
    # MOD4 CASE
    add(generate_i_type(0x03, 8, 0, 2, c_mod4)) 
    add(generate_i_type(0x13, 8, 8, 0, 1))
    add(generate_s_type(0x23, 0, 8, c_mod4))
    
    instructions[branch_mod4_idx] = generate_b_type(0x63, 5, 0, 1, (len(instructions)-branch_mod4_idx)*4) 
    
    # 6. Check Threshold
    # BGE x4, x9, skip (x9=thresh)
    branch_thresh_idx = len(instructions)
    add(0)
    
    # BELOW CASE
    add(generate_i_type(0x03, 8, 0, 2, c_thresh))
    add(generate_i_type(0x13, 8, 8, 0, 1))
    add(generate_s_type(0x23, 0, 8, c_thresh))
    
    # SKIP THRESH
    instructions[branch_thresh_idx] = generate_b_type(0x63, 4, 9, 5, (len(instructions)-branch_thresh_idx)*4)
    
    # --- LOOP END MAINTENANCE ---
    
    # Increment Iterator: ADDI x1, x1, 1
    add(generate_i_type(0x13, 1, 1, 0, 1))
    # Increment Input Pointer by 4
    add(generate_i_type(0x13, 3, 3, 0, 4))
    
    # Jump Back to Start
    offset_back = (loop_check_idx - len(instructions)) * 4
    add(generate_j_type(0x6F, 0, offset_back))
    
    # PATCH LOOP CHECK
    offset_end = (len(instructions) - loop_check_idx) * 4
    instructions[loop_check_idx] = generate_b_type(0x63, 1, 2, 5, offset_end) # BGE i, count
    
    # END LOOP 
    add(0x00000013) # NOP
    add(0x00000013) # NOP
    add(0x00000013) # NOP
    
    # ---------------------------------------------------------
    # 3. OUTPUT
    # ---------------------------------------------------------
    
    with open(args.out, "w") as f:
        for inst in instructions:
            f.write(to_hex_str(inst) + "\n")
            
    # Expected Memory State file
    with open(args.mem, "w") as f:
        # Inputs 
        for i, val in enumerate(inputs):
            f.write(f"M[{i*4}]: {to_hex_str(val)}\n") # Word Address
        # Zeros between
        for i in range(len(inputs)*4, counter_base):
             f.write(f"M[{i}]: 00000000\n")
             
        # Counters
        # c_mod4 etc are absolute indices
        # We need to output sequential M[i] entries
        
        # We expect counters at:
        # c_odd (CB+0), c_even (CB+4), c_neg (CB+8), c_mod4 (CB+12), c_thresh (CB+16)
        
        f.write(f"M[{c_odd}]: {to_hex_str(exp_odd)}\n")
        f.write(f"M[{c_even}]: {to_hex_str(exp_even)}\n")
        f.write(f"M[{c_neg}]: {to_hex_str(exp_neg)}\n")
        f.write(f"M[{c_mod4}]: {to_hex_str(exp_mod4)}\n")
        f.write(f"M[{c_thresh}]: {to_hex_str(exp_thresh)}\n")
        
    print(f"Generated {len(instructions)} instructions.")

if __name__ == "__main__":
    main()
