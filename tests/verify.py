import os
import glob
import sys
import shutil
import datetime
import argparse
from riscv_model import RISCV_Model

# --- Configuration ---
RESULTS_DIR = "results"
DEFAULT_INSTR_FILE = "../instructions/instr.txt"
SIM_LOG_FILE = "simulation.log"

def run_command_capture(cmd, log_file_path=None):
    """
    Runs a shell command. Captures stdout/stderr.
    Filters 'VCD warning' from console output but logs everything to file.
    """
    import subprocess
    
    # Run process
    process = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
    
    full_output = []
    clean_output = []
    
    while True:
        line = process.stdout.readline()
        if not line and process.poll() is not None:
            break
        if line:
            full_output.append(line)
            # Filter Noise
            if "VCD warning" not in line and "dumpfile" not in line and "open for output" not in line:
                print(line, end='') # Print to console
                clean_output.append(line)
                
    ret = process.poll()
    
    # Write to Log File
    if log_file_path:
        with open(log_file_path, "w") as f:
            f.writelines(full_output)
            
    if ret != 0:
        print(f"Error executing command: {cmd}")
        return False
    return True

def parse_reg_file(filepath):
    regs = {}
    if not os.path.exists(filepath): return {}
    try:
        with open(filepath, 'r') as f:
            for line in f:
                parts = line.strip().split(':')
                if len(parts) == 2:
                    try:
                        regs[parts[0].strip()] = int(parts[1].strip(), 16)
                    except ValueError: pass
        return regs
    except: return {}

def parse_dmem_file(filepath):
    dmem = {}
    if not os.path.exists(filepath): return dmem
    with open(filepath, 'r') as f:
        for line in f:
            line = line.strip()
            if line.startswith("M[") and "]:" in line:
                try:
                    parts = line.split("]:")
                    idx = int(parts[0].replace("M[", ""))
                    val = int(parts[1].strip(), 16)
                    dmem[idx] = val
                except: pass
    return dmem

def setup_run_directory(mode):
    timestamp = datetime.datetime.now().strftime("%Y%m%d_%H%M%S")
    run_dir = os.path.join(RESULTS_DIR, f"Run_{timestamp}_{mode.upper()}")
    os.makedirs(run_dir, exist_ok=True)
    return run_dir

def run_test_case(test_path, model, run_dir):
    test_name = os.path.basename(test_path)
    print(f"Testing: {test_name}")
    
    # 1. Reset Model
    model.reset()
    
    # 2. Prepare Instruction Stream
    final_hex_instructions = []
    # Prologue (Init Registers)
    for r in range(1, 32):
        inst = (r << 7) | 0x13
        final_hex_instructions.append(inst)
        model.step_hex(inst)
        
    # User Test
    with open(test_path, 'r') as f:
        for line in f:
            line = line.strip()
            if not line: continue
            try:
                inst = int(line, 16)
                final_hex_instructions.append(inst)
                model.step_hex(inst, trace=True)
            except ValueError: pass

    # 3. Write Instruction File to Run Dir
    # Handle extension: if test_path ends in .txt or .hex, preserve base name
    base, ext = os.path.splitext(test_name)
    if ext not in ['.txt', '.hex']: base = test_name
    
    hex_filename = f"{base}.hex"
    hex_file_path = os.path.join(run_dir, hex_filename)
    
    with open(hex_file_path, "w") as f:
        for inst in final_hex_instructions:
            f.write(f"{inst:08x}\n")
            
    # 4. Run Simulation
    # Force Recompile to ensure I_mem changes are picked up
    os.system("make -C .. -B a.out > /dev/null 2>&1")
    
    # Run Simulation
    # Use ASCII-safe relative path (relative to Makefile/Root)
    # verify.py is in tests/, run_dir is in tests/results/
    # So path from root is tests/results/...
    # hex_file_path is relative to verify.py (e.g. results/Run.../test.hex)
    safe_rel_path = os.path.join("tests", hex_file_path)
    
    log_file = os.path.join(run_dir, f"{base}.log")
    
    cmd = f"make -C .. run ARGS=+TESTFILE={safe_rel_path}" 
    success = run_command_capture(cmd, log_file)
    
    if not success:
        return False

    # 5. Verify Registers
    # Simulator writes reg_dump.txt to CWD (..)
    # Move it to run_dir
    # Check BOTH ../reg_dump.txt (if CWD=tests/) AND reg_dump.txt (if CWD=root)
    src_reg_dump_rel = "../reg_dump.txt"
    src_reg_dump_cwd = "reg_dump.txt"
    dst_reg_dump = os.path.join(run_dir, f"{base}_reg_dump.txt")
    
    if os.path.exists(src_reg_dump_rel):
        shutil.move(src_reg_dump_rel, dst_reg_dump)
    elif os.path.exists(src_reg_dump_cwd):
        shutil.move(src_reg_dump_cwd, dst_reg_dump)
    else:
        print("  FATAL: No register dump generated.")
        return False
        
    actual = parse_reg_file(dst_reg_dump)
    errors = 0
    error_msgs = []
    
    for i in range(32):
        reg = f"x{i}"
        exp = model.regs[i] & 0xFFFFFFFF
        act = actual.get(reg, 0) & 0xFFFFFFFF
        if exp != act:
            msg = f"  FAIL: {reg} | Exp: {exp:x} | Got: {act:x}"
            print(msg)
            error_msgs.append(msg)
            errors += 1
            
    if errors == 0:
        print("  ✅ PASS")
        return True
    else:
        print(f"  ❌ FAIL ({errors} mismatches)")
        with open(os.path.join(run_dir, f"{test_name}_failure.txt"), "w") as f:
            f.write("\n".join(error_msgs))
        return False

def run_histogram_test(test_name, count, seed, run_dir):
    print("\n----------------------------------------")
    print(f"Testing: {test_name} (Count={count}, Seed={seed})")
    
    test_file_base = test_name.replace(" ", "_").replace("(", "").replace(")", "")
    gen_hex_file = os.path.join(run_dir, f"{test_file_base}.hex")
    exp_mem_file = os.path.join(run_dir, f"{test_file_base}_expected_dmem.txt")
    
    # Generate
    import subprocess
    cmd = ["python3", "test_histogram.py", 
           "--count", str(count), 
           "--out", gen_hex_file, 
           "--mem", exp_mem_file]
    if seed is not None: cmd.extend(["--seed", str(seed)])
        
    ret = subprocess.call(cmd, stdout=subprocess.DEVNULL)
    if ret != 0:
        print("Generation Failed")
        return False
        
    # Run Simulation
    os.system("make -C .. a.out > /dev/null 2>&1")
    safe_rel_path = os.path.join("tests", gen_hex_file)
    log_file = os.path.join(run_dir, f"{test_file_base}.log")
    
    cmd = f"make -C .. run ARGS=+TESTFILE={safe_rel_path}" 
    run_command_capture(cmd, log_file)
    
    # Verify Memory
    # Move dumps
    src_dmem_rel = "../dmem_dump.txt"
    src_dmem_cwd = "dmem_dump.txt"
    dst_dmem = os.path.join(run_dir, f"{test_file_base}_dmem_dump.txt")
    
    if os.path.exists(src_dmem_rel): shutil.move(src_dmem_rel, dst_dmem)
    elif os.path.exists(src_dmem_cwd): shutil.move(src_dmem_cwd, dst_dmem)
    
    # Cleanup unused reg_dump from histogram run
    for f in ["../reg_dump.txt", "reg_dump.txt"]:
        if os.path.exists(f): 
            try: os.remove(f)
            except: pass
    
    actual = parse_dmem_file(dst_dmem)
    expected_lines = []
    if os.path.exists(exp_mem_file):
        with open(exp_mem_file) as f: expected_lines = f.readlines()
        
    errors = 0
    report_lines = []
    for line in expected_lines:
        line = line.strip()
        if not line: continue
        try:
            parts = line.split("]:")
            idx = int(parts[0].replace("M[", ""))
            exp_val = int(parts[1].strip(), 16)
            act_val = actual.get(idx, 0)
            if exp_val != act_val:
                msg = f"  FAIL: M[{idx}] | Exp: {exp_val:x} | Got: {act_val:x}"
                print(msg)
                report_lines.append(msg)
                errors += 1
        except: pass
        
    if errors == 0:
        print("  ✅ Memory Check PASS")
        return True
    else:
        print(f"  ❌ Memory Check FAIL ({errors} mismatches)")
        with open(os.path.join(run_dir, f"{test_file_base}_failure.txt"), "w") as f:
            f.write("\n".join(report_lines))
        return False

def main(rand_count, hist_count, seed=None):
    print("=== RV32I Verification Suite ===")
    
    # Setup Directory
    mode_str = "CUSTOM"
    if rand_count == 20: mode_str = "QUICK"
    elif rand_count == 1000: mode_str = "STRESS"
    elif rand_count == 100: mode_str = "STANDARD"
    
    run_dir = setup_run_directory(mode_str)
    print(f"Results Directory: {run_dir}\n")
    
    results = []
    model = RISCV_Model()
    
    # 1. Random Test
    seed_arg = f"--seed {seed}" if seed is not None else ""
    print(f"[Gen] Generating Random Tests (Count={rand_count}, Seed={seed})...")
    
    # Proactive Cleanup of Leftovers in Root/CWD
    for f in ["../reg_dump.txt", "../expected_regs.txt", "reg_dump.txt", "expected_regs.txt", "../dmem_dump.txt"]:
        if os.path.exists(f): 
            try: os.remove(f)
            except: pass
    
    os.system(f"python3 test_gen.py --count {rand_count} {seed_arg}")
    
    # Move generated test to run_dir for archival
    if os.path.exists("generated_test.txt"):
        shutil.move("generated_test.txt", os.path.join(run_dir, "random_test_source.hex"))
        
    # Check BOTH cwd and parent for expected_regs.txt (just in case)
    if os.path.exists("expected_regs.txt"):
        shutil.move("expected_regs.txt", os.path.join(run_dir, "expected_regs.txt"))
    elif os.path.exists("../expected_regs.txt"):
        shutil.move("../expected_regs.txt", os.path.join(run_dir, "expected_regs.txt"))
        
    # We need to read it back in run_test_case?
    # run_test_case expects a path.
    res1 = run_test_case(os.path.join(run_dir, "random_test_source.hex"), model, run_dir)
    results.append(res1)
    
    # 2. Manual Tests
    manual_tests = glob.glob("manual/*.hex")
    for t in manual_tests:
        res = run_test_case(t, model, run_dir)
        results.append(res)
        
    # 3. Histogram
    res_micro = run_histogram_test("Histogram (Micro)", 5, 42, run_dir)
    results.append(res_micro)
    
    if hist_count != 5:
        res_std = run_histogram_test("Histogram (Configured)", hist_count, seed if seed else 123, run_dir)
        results.append(res_std)
        
    # Report
    pass_cnt = sum(1 for r in results if r)
    total = len(results)
    print("========================================")
    print(f"Summary: {pass_cnt}/{total} Tests Passed")
    print(f"Full Report: {run_dir}")
    
    # Generate Report.md
    with open(os.path.join(run_dir, "report.md"), "w") as f:
        f.write(f"# Verification Report\n")
        f.write(f"Date: {datetime.datetime.now()}\n")
        f.write(f"Mode: {mode_str}\n")
        f.write(f"Seed: {seed}\n")
        f.write(f"Status: {'PASS' if pass_cnt==total else 'FAIL'}\n\n")
        f.write(f"Summary: {pass_cnt}/{total} Tests Passed\n")
        
    if pass_cnt != total: sys.exit(1)
    else: sys.exit(0)

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--mode", choices=["quick", "standard", "stress"], default="standard")
    parser.add_argument("--rand-count", type=int)
    parser.add_argument("--hist-count", type=int)
    parser.add_argument("--seed", type=int)
    args = parser.parse_args()
    
    rand_cnt = 100
    hist_cnt = 20
    seed = None
    
    if args.mode == "quick":
        rand_cnt = 20
        hist_cnt = 5
        seed = 42
    elif args.mode == "stress":
        rand_cnt = 1000
        hist_cnt = 100
        seed = 12345
        
    if args.rand_count: rand_cnt = args.rand_count
    if args.hist_count: hist_cnt = args.hist_count
    if args.seed: seed = args.seed
    
    main(rand_cnt, hist_cnt, seed)
