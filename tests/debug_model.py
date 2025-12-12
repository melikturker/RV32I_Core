from riscv_model import RISCV_Model

def test():
    m = RISCV_Model()
    # Test I-Type
    inst = 0x00a00313 # ADDI x6, x0, 10
    print(f"{hex(inst)} -> {m.disassemble(inst)}")
    
    # Test Branch
    inst = 0xfe000ce3 # BEQ x0, x0, -4 (Infinite loop)
    print(f"{hex(inst)} -> {m.disassemble(inst)}")
    
    # Test S-Type
    inst = 0x00aa0023 # SB x10, 0(x20)
    print(f"{hex(inst)} -> {m.disassemble(inst)}")
    
    # Test Unknown
    inst = 0xFFFFFFFF
    print(f"{hex(inst)} -> {m.disassemble(inst)}")

if __name__ == "__main__":
    test()
