#!/usr/bin/env python3
import random
import sys

def to_hex_str(val, bits=32):
    return f"{val & ((1<<bits)-1):0{bits//4}x}"

# Instruction Generators
def generate_i_type(opcode, rd, rs1, funct3, imm):
    inst = (imm & 0xFFF) << 20 | (rs1 & 0x1F) << 15 | (funct3 & 0x7) << 12 | (rd & 0x1F) << 7 | (opcode & 0x7F)
    return inst

def generate_r_type(opcode, rd, rs1, rs2, funct3, funct7):
    inst = (funct7 & 0x7F) << 25 | (rs2 & 0x1F) << 20 | (rs1 & 0x1F) << 15 | (funct3 & 0x7) << 12 | (rd & 0x1F) << 7 | (opcode & 0x7F)
    return inst

def generate_u_type(opcode, rd, imm):
    inst = (imm & 0xFFFFF) << 12 | (rd & 0x1F) << 7 | (opcode & 0x7F)
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
    imm20 = (imm >> 20) & 0x1
    imm10_1 = (imm >> 1) & 0x3FF
    imm11 = (imm >> 11) & 0x1
    imm19_12 = (imm >> 12) & 0xFF
    inst = (imm20 << 31) | (imm19_12 << 12) | (imm11 << 20) | (imm10_1 << 21) | (rd & 0x1F) << 7 | (opcode & 0x7F)
    return inst

def main(count=100, seed=None, out_file="random_test.hex"):
    if seed is not None:
        random.seed(seed)
        print(f"Generating {count} random instructions (Seed={seed})...")
    else:
        print(f"Generating {count} random instructions...")
    
    instructions = []
    
    # Init registers x1-x31 to avoid X propagation (optional but good practice)
    for i in range(1, 32):
        inst = generate_i_type(0x13, i, 0, 0, i) # ADDI xi, x0, i
        instructions.append(inst)

    for _ in range(count):
        instr_type = random.choice([0, 1, 2, 3, 4, 5, 6])
        
        rd = random.randint(1, 31)
        rs1 = random.randint(0, 31)
        rs2 = random.randint(0, 31)
        
        # Limit immediates for safety
        imm12 = random.randint(-16, 15) 
        imm20 = random.randint(0, 0xFF)
        bj_offset = random.choice([4, 8, -4, 0]) # Very local jumps to avoid infinite loops or crashes
        
        inst = 0
        
        if instr_type == 0: # R-Type
             ops = [
                (0x0, 0x00), (0x0, 0x20), # ADD, SUB
                (0x4, 0x00), (0x6, 0x00), (0x7, 0x00), # XOR, OR, AND
                (0x1, 0x00), (0x5, 0x00) # SLL, SRL
            ]
             funct3, funct7 = random.choice(ops)
             inst = generate_r_type(0x33, rd, rs1, rs2, funct3, funct7)

        elif instr_type == 1: # I-Type ALU
            i_ops = [0x0, 0x4, 0x6, 0x7, 0x2, 0x3] # ADDI..SLTIU
            funct3 = random.choice(i_ops)
            inst = generate_i_type(0x13, rd, rs1, funct3, imm12)
            
        elif instr_type == 2: # U-Type
            op = random.choice([0x37, 0x17]) # LUI, AUIPC
            inst = generate_u_type(op, rd, imm20)
            
        elif instr_type == 3: # Load
             # LW (aligned)
             addr = random.randint(0, 32) * 4
             inst = generate_i_type(0x03, rd, 0, 0x2, addr) # LW from x0+addr
             
        elif instr_type == 4: # Store
             # SW
             addr = random.randint(0, 32) * 4
             inst = generate_s_type(0x23, 0, rs2, addr) # SW rs2 to x0+addr
             
        elif instr_type == 5: # Branch
            inst = generate_b_type(0x63, rs1, rs2, 0, bj_offset) # BEQ
            
        elif instr_type == 6: # Jump
            # JAL simple forward
            inst = generate_j_type(0x6F, rd, 4) 
        
        instructions.append(inst)
        
    # Write Instruction File
    try:
        with open(out_file, "w") as f:
            for inst in instructions:
                f.write(to_hex_str(inst) + "\n")
        print(f"Success: Written to {out_file}")
    except OSError as e:
        print(f"Error writing file: {e}")
        sys.exit(1)

if __name__ == "__main__":
    import argparse
    parser = argparse.ArgumentParser()
    parser.add_argument("--count", type=int, default=100, help="Number of random instructions")
    parser.add_argument("--seed", type=int, help="Random Seed")
    parser.add_argument("--out", type=str, default="generated_test.hex", help="Output hex file")
    args = parser.parse_args()
    
    main(args.count, args.seed, args.out)
