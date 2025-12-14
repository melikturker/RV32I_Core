#!/usr/bin/env python3
import os
import sys
import subprocess
import shutil
import random
import datetime
import argparse
import glob

# --- Configuration ---
TEST_GEN_SCRIPT = os.path.join("tests", "test_gen.py")
HIST_GEN_SCRIPT = os.path.join("tests", "test_histogram.py")
SIM_BINARY = "./tests/sim_headless" # Updated location
RESULTS_BASE = "tests/results"
MANUAL_TESTS_DIR = "tests/manual"

# --- Interface ---
def parse_reg_dump(filepath):
    """Parses reg_dump.txt from Verilator (x0: 0 ... x31: ...)"""
    regs = {}
    if not os.path.exists(filepath): return None
    
    with open(filepath, 'r') as f:
        for line in f:
            parts = line.strip().split(':')
            if len(parts) == 2:
                reg_name = parts[0].strip()
                val_hex = parts[1].strip()
                try: regs[reg_name] = int(val_hex, 16)
                except: pass
    return regs

def parse_dmem_dump(filepath):
    """Parses dmem_dump.txt (M[addr]: val)"""
    mem = {}
    if not os.path.exists(filepath): return mem
    with open(filepath, 'r') as f:
        for line in f:
            line = line.strip()
            if line.startswith("M[") and "]:" in line:
                try:
                    parts = line.split("]:")
                    idx = int(parts[0].replace("M[", ""))
                    val = int(parts[1].strip(), 16)
                    mem[idx] = val
                except: pass
    return mem

def run_simulation(test_hex_path, run_dir, test_name, trace=False):
    """Running the binary against a hex file."""
    # Resolve absolute path to avoid CWD/Wildcard issues
    abs_hex_path = os.path.abspath(test_hex_path)
    
    cmd = [SIM_BINARY, f"+TESTFILE={abs_hex_path}", "+DUMP"]
    
    if trace:
        cmd.append("+TRACE")
        
    log_file = os.path.join(run_dir, f"trace_{test_name}.log")
    
    # Run
    try:
        with open(log_file, "w") as outfile:
             subprocess.run(cmd, stdout=outfile, stderr=subprocess.STDOUT, check=True, timeout=15)
    except subprocess.TimeoutExpired:
        print(" TIMEOUT")
        return False
    except subprocess.CalledProcessError:
        print(" SIM ERROR")
        return False
    except FileNotFoundError:
        print(" BINARY MISSING")
        return False

    # Collect Artifacts (sim_headless output to CWD, or maybe relative to binary?)
    # usually CWD.
    reg_dump = "reg_dump.txt"
    dmem_dump = "dmem_dump.txt"
    
    if os.path.exists(reg_dump):
        shutil.move(reg_dump, os.path.join(run_dir, f"regs_{test_name}.txt"))
    else:
        print(" NO REG DUMP")
        return False
        
    if os.path.exists(dmem_dump):
        shutil.move(dmem_dump, os.path.join(run_dir, f"mem_{test_name}.txt"))
        
    return True

def verify_histogram(run_dir, test_name, expected_mem_file):
    """Compares generated memory dump against expected."""
    mem_file = os.path.join(run_dir, f"mem_{test_name}.txt")
    if not os.path.exists(mem_file): return False
    
    actual = parse_dmem_dump(mem_file)
    errors = 0
    
    if not os.path.exists(expected_mem_file):
        print(" NO EXPECTED FILE")
        return False
        
    with open(expected_mem_file, 'r') as f:
        for line in f:
            line = line.strip()
            if not line: continue
            try:
                parts = line.split("]:")
                idx = int(parts[0].replace("M[", ""))
                exp_val = int(parts[1].strip(), 16)
                act_val = actual.get(idx, 0) # Default to 0 if missing in dump (e.g. 0x0)
                
                # Check mismatch
                if exp_val != act_val:
                    if errors < 5: 
                        print(f"\n   FAIL M[{idx}]: Exp={hex(exp_val)} Got={hex(act_val)}", end='')
                    errors += 1
            except: pass
            
    if errors == 0:
        print(" PASS")
        return True
    else:
        print(f" FAIL ({errors} mismatches)")
        return False

def verify_generic(run_dir, test_name):
    """Sanity Check for Random/Corner cases (x0=0)"""
    reg_file = os.path.join(run_dir, f"regs_{test_name}.txt")
    regs = parse_reg_dump(reg_file)
    if not regs: 
        print(" PARSE ERROR")
        return False
        
    if regs.get('x0', -1) != 0:
        print(" FAIL (x0!=0)")
        return False
        
    print(" PASS (Exec)")
    return True

def main(mode, specific_test=None, trace=False):
    # Setup
    timestamp = datetime.datetime.now().strftime("%Y%m%d_%H%M%S")
    run_dir = os.path.join(RESULTS_BASE, f"Run_{timestamp}_{mode.upper()}")
    os.makedirs(run_dir, exist_ok=True)
    
    print(f"=== RV32I Verification Suite [{mode.upper()}] ===")
    print(f"Results: {run_dir}")

    # Build
    print("[Build] Compiling Simulator...")
    try:
        subprocess.run(["make", "verilate_headless"], check=True, stdout=subprocess.DEVNULL)
    except:
        print("Build Failed")
        sys.exit(1)
    
    # Tests Collection
    tests = []
    
    if mode == "quick":
        tests.append(("Random", "random", 20, False)) # name, type, count, is_hist
        tests.append(("Histogram", "histogram", 5, True))
    elif mode == "standard":
        tests.append(("Random", "random", 100, False))
        tests.append(("Histogram", "histogram", 20, True))
    elif mode == "stress":
        tests.append(("Random", "random", 1000, False))
        tests.append(("Histogram", "histogram", 100, True))
    
    # Manual Tests Scan
    manual_files = glob.glob(os.path.join(MANUAL_TESTS_DIR, "*.hex"))
    for mf in manual_files:
        basename = os.path.basename(mf).replace(".hex", "")
        tests.append((f"Manual: {basename}", "manual", mf, False))
        
    # Execution
    summary = []
    
    for t_name, t_type, t_arg, is_hist in tests:
        if specific_test and specific_test.lower() not in t_name.lower():
            continue
            
        print(f"   [Test] {t_name} ... ", end='', flush=True)
        
        hex_file = ""
        exp_file = ""
        
        try:
            if t_type == "random":
                 subprocess.run([sys.executable, TEST_GEN_SCRIPT, "--count", str(t_arg), "--out", "random.hex", "--reg", "expected_regs.txt"], check=True, stdout=subprocess.DEVNULL)
                 hex_file = "random.hex"
                 
            elif t_type == "histogram":
                 subprocess.run([sys.executable, HIST_GEN_SCRIPT, "--count", str(t_arg), "--out", "histogram.hex", "--mem", "hist_expected.txt"], check=True, stdout=subprocess.DEVNULL)
                 hex_file = "histogram.hex"
                 exp_file = "hist_expected.txt"
                 
            elif t_type == "manual":
                 hex_file = t_arg
        except subprocess.CalledProcessError:
            print(" GEN FAIL")
            summary.append((t_name, "GEN_FAIL"))
            continue
             
        # Run Sim
        success = run_simulation(hex_file, run_dir, t_name.replace(" ", "_").replace(":", ""), trace)  
        if not success:
             print(" EXEC FAIL")
             summary.append((t_name, "FAIL"))
             continue
             
        # Verify
        if is_hist:
             if verify_histogram(run_dir, t_name.replace(" ", "_").replace(":", ""), exp_file):
                 summary.append((t_name, "PASS"))
             else:
                 summary.append((t_name, "FAIL"))
        else:
             if verify_generic(run_dir, t_name.replace(" ", "_").replace(":", "")):
                 summary.append((t_name, "PASS"))
             else:
                 summary.append((t_name, "FAIL"))

    print("\n----------------------------------------")
    print(f"Summary: {sum(1 for _, s in summary if s=='PASS')}/{len(summary)} Passed")
    print("----------------------------------------")

    # Cleanup Source Dumps if any left
    for f in ["reg_dump.txt", "dmem_dump.txt", "generated_test.txt", "random.hex", "histogram.hex", "hist_expected.txt", "expected_regs.txt"]:
        if os.path.exists(f): os.remove(f)

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--mode", default="quick", choices=["quick", "standard", "stress"])
    parser.add_argument("--test", default=None, help="Run specific test name only")
    parser.add_argument("--trace", action="store_true", help="Enable VCD generation")
    
    args = parser.parse_args()
    main(args.mode, args.test, args.trace)
