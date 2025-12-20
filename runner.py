#!/usr/bin/env python3
import os
import sys
import subprocess
import argparse
import shutil
import re

# --- Configuration ---
PROJECT_ROOT = os.path.dirname(os.path.abspath(__file__))
BUILD_DIR = os.path.join(PROJECT_ROOT, "build")
SRC_DIR = os.path.join(PROJECT_ROOT, "src")
TOOLS_DIR = os.path.join(PROJECT_ROOT, "tools")
APP_DIR = os.path.join(PROJECT_ROOT, "app")
TEST_LOG = os.path.join(BUILD_DIR, "test_results.log")

# --- Helper Functions ---
def log(msg):
    print(f"🔹 {msg}")

def log_success(msg):
    print(f"✅ {msg}")

def log_error(msg):
    print(f"❌ {msg}")

def run_cmd(cmd, cwd=PROJECT_ROOT, silent=False):
    if not silent:
        log(f"Running: {cmd}")
    try:
        # Redirect stdout/stderr if silent
        stdout = subprocess.DEVNULL if silent else None
        subprocess.check_call(cmd, shell=True, cwd=cwd, stdout=stdout)
    except subprocess.CalledProcessError as e:
        if not silent:
            log_error(f"Command failed: {cmd}")
        sys.exit(e.returncode)

def check_env():
    """Verify essential tools are available."""
    tools = ["verilator", "make", "g++", "sdl2-config", "python3"]
    missing = []
    for tool in tools:
        if shutil.which(tool) is None:
            missing.append(tool)
    
    if missing:
        log_error(f"Missing system tools: {', '.join(missing)}")
        sys.exit(1)
    
    # log("Environment OK.") # Reduced verbosity

# --- Commands ---
def cmd_check(args):
    check_env()
    log_success("System Environment Check Passed.")

def cmd_clean(args):
    log("Cleaning build artifacts...")
    if os.path.exists(BUILD_DIR):
        shutil.rmtree(BUILD_DIR)
    
    # Also clean make artifacts via make if Makefile exists
    if os.path.exists("Makefile"):
        run_cmd("make clean", silent=True)
    
    log_success("Cleaned project workspace.")

def cmd_build(args):
    if args.mode not in ["headless", "gui", "coverage"]:
        log_error("Invalid mode. Use --mode headless, --mode gui, or --mode coverage")
        sys.exit(1)
    
    # Ensure build dir exists
    os.makedirs(BUILD_DIR, exist_ok=True)
    
    target = args.mode # 'headless' or 'gui'
    # log(f"Building target: {target}...")
    run_cmd(f"make {target} -s", silent=False) # Keep make output visible if needed, or silent? User wanted prettier logic.
    # Makefile is mostly silent now due to modifications, only prints custom echos.

# --- Helper Functions ---
def detect_gui_needed(file_path):
    """Detect if the application requires GUI (VRAM usage)."""
    try:
        with open(file_path, 'r', errors='ignore') as f:
            content = f.read()
            # Simple heuristic: Look for VRAM base address or keyword
            if "VRAM_BASE" in content or "0x8000" in content or "0x00008000" in content:
                return True
            # Also check for explicit header comment if we add one later
            if "@GUI" in content:
                return True
    except Exception:
        pass
    return False

def cmd_run(args):
    # Detect file type of the application
    app_path = os.path.abspath(args.file)
    if not os.path.exists(app_path):
        log_error(f"Application file not found: {app_path}")
        sys.exit(1)
    
    ext = os.path.splitext(app_path)[1]
    
    # Auto-Detect Mode
    use_gui = detect_gui_needed(app_path)
    mode_str = "gui" if use_gui else "headless"
    sim_bin_name = "sim_gui" if use_gui else "sim_headless"
    
    # Ensure simulator exists (Auto-build if needed)
    sim_bin = os.path.join(BUILD_DIR, sim_bin_name)
    if not os.path.exists(sim_bin):
        log(f"Simulator binary ({sim_bin_name}) not found. Building first...")
        args.mode = mode_str
        cmd_build(args)
    
    # Prepare Hex File
    hex_path = os.path.join(BUILD_DIR, "app.hex")
    
    if ext == ".s":
        # Assemble Assembly file
        log(f"Assembling {os.path.basename(args.file)}")
        assembler_script = os.path.join(TOOLS_DIR, "assembler.py")
        if not os.path.exists(assembler_script):
            log_error(f"Assembler not found at {assembler_script}")
            sys.exit(1)

        run_cmd(f"python3 {assembler_script} {app_path} {hex_path}", silent=True)
        
    elif ext == ".hex" or ext == ".txt":
        # Use directly
        log(f"Using hex file: {os.path.basename(args.file)}")
        shutil.copy(app_path, hex_path)
    else:
        log_error(f"Unsupported file type: {ext}")
        sys.exit(1)
            
    # Run Simulation
    log(f"Launching simulation [{mode_str}] (Auto-Detected)...")
    cmd = f"{sim_bin} +TESTFILE={hex_path}"
    
    try:
        subprocess.check_call(cmd, shell=True, cwd=PROJECT_ROOT)
    except subprocess.CalledProcessError:
        log_error("Simulation failed.")
        sys.exit(1)
    except KeyboardInterrupt:
        print("\n")
        log("Simulation interrupted by user.")


def cmd_test(args):
    # Build headless simulator first if needed
    sim_bin = os.path.join(BUILD_DIR, "sim_headless")
    if not os.path.exists(sim_bin):
        log("Building headless simulator...")
        build_args = argparse.Namespace(mode="headless")
        cmd_build(build_args)

    print("\n🧪 Running Regression Tests...")
    print("-" * 65)
    print(f"{'TEST CASE':<45} | {'RESULT':<10}")
    print("-" * 65)
    
    tests = []
    
    # Determine which test categories to run
    run_functional = args.functionality or (not args.functionality and not args.performance)
    run_performance = args.performance or (not args.functionality and not args.performance)
    
    # === FUNCTIONALITY TESTS ===
    if run_functional:
        # 1. Random Corner Case Test
        random_hex = os.path.join(BUILD_DIR, "random_corner_test.hex")
        gen_script = os.path.join(TOOLS_DIR, "random_instruction_test_gen.py")
        
        if os.path.exists(gen_script):
            seed_arg = f"--seed {args.seed}" if args.seed is not None else ""
            cmd_gen = f"python3 {gen_script} --out {random_hex} --count {args.count} {seed_arg}"
            
            try:
                subprocess.check_call(cmd_gen, shell=True, cwd=PROJECT_ROOT, stdout=subprocess.DEVNULL)
                tests.append(("Random Corner Case Test", random_hex, "functional"))
            except subprocess.CalledProcessError:
                 log_error("Failed to generate random test.")
        
        # 2. Functional Tests (hazard, corner, matrix, ISA coverage)
        func_dir = os.path.join(PROJECT_ROOT, "tests", "functional")
        if os.path.exists(func_dir):
            # Assemble .s files first
            assembler_script = os.path.join(TOOLS_DIR, "assembler.py")
            for f in sorted(os.listdir(func_dir)):
                if f.endswith(".s"):
                    # Assemble to hex
                    asm_path = os.path.join(func_dir, f)
                    hex_name = f.replace(".s", ".hex")
                    hex_path = os.path.join(func_dir, hex_name)
                    
                    try:
                        subprocess.check_call(
                            f"python3 {assembler_script} {asm_path} {hex_path}",
                            shell=True, cwd=PROJECT_ROOT, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL
                        )
                    except subprocess.CalledProcessError:
                        log_error(f"Failed to assemble {f}")
                        continue
            
            # Now collect all hex files
            for f in sorted(os.listdir(func_dir)):
                if f.endswith(".hex"):
                    tests.append((f, os.path.join(func_dir, f), "functional"))
    
    # === PERFORMANCE TESTS ===
    if run_performance:
        # Performance hex tests (future: benchmark tests)
        perf_dir = os.path.join(PROJECT_ROOT, "tests", "performance")
        if os.path.exists(perf_dir):
            for f in sorted(os.listdir(perf_dir)):
                if f.endswith(".hex"):
                    tests.append((f, os.path.join(perf_dir, f), "performance"))

    if not tests:
        log_error("No tests found to run.")
        return

    passed_count = 0
    failed_count = 0
    
    for test_name, test_path, category in tests:
        cmd = f"{sim_bin} +TESTFILE={test_path}"
        
        try:
            result = subprocess.run(cmd, shell=True, cwd=PROJECT_ROOT, 
                                  stdout=subprocess.PIPE, stderr=subprocess.STDOUT, 
                                  text=True, timeout=10)
            output = result.stdout
            
            if "Simulation PASSED" in output and result.returncode == 0:
                print(f"{test_name:<45} | \033[92m✅ PASS\033[0m")
                passed_count += 1
            else:
                print(f"{test_name:<45} | \033[91m❌ FAIL\033[0m")
                failed_count += 1
                
                # Create logs directory if it doesn't exist
                log_dir = os.path.join(PROJECT_ROOT, "logs")
                os.makedirs(log_dir, exist_ok=True)
                
                # Generate log filename with timestamp
                import datetime
                timestamp = datetime.datetime.now().strftime("%Y%m%d_%H%M%S")
                log_file = os.path.join(log_dir, f"test_fail_{test_name.replace('.hex', '')}_{timestamp}.log")
                
                # Write detailed log
                with open(log_file, 'w') as f:
                    f.write(f"=== TEST FAILURE REPORT ===\n")
                    f.write(f"Test: {test_name}\n")
                    f.write(f"Category: {category}\n")
                    f.write(f"Test File: {test_path}\n")
                    f.write(f"Exit Code: {result.returncode}\n")
                    f.write(f"Timestamp: {timestamp}\n")
                    f.write(f"\n=== SIMULATION OUTPUT ===\n")
                    f.write(output)
                    f.write(f"\n\n=== ANALYSIS ===\n")
                    
                    # Extract useful debug info
                    if "TIMEOUT" in output or result.returncode == -9:
                        f.write("Likely cause: TIMEOUT - simulation did not complete in time\n")
                        f.write("Suggestion: Check for infinite loops or increase timeout value\n")
                    elif "Segmentation fault" in output:
                        f.write("Likely cause: Memory access violation\n")
                    elif result.returncode != 0:
                        f.write(f"Non-zero exit code: {result.returncode}\n")
                    
                    f.write("\n=== LAST 20 LINES ===\n")
                    output_lines = output.strip().split('\n')
                    last_lines = output_lines[-20:] if len(output_lines) > 20 else output_lines
                    f.write('\n'.join(last_lines))
                
                # Print summary to console
                print(f"  \033[93m📝 Detailed log saved: {log_file}\033[0m")
                print(f"  Exit code: {result.returncode}\n")
                
        except subprocess.TimeoutExpired:
            print(f"{test_name:<45} | \033[93m⏱️  TIMEOUT\033[0m")
            failed_count += 1
            
            # Log timeout
            log_dir = os.path.join(PROJECT_ROOT, "logs")
            os.makedirs(log_dir, exist_ok=True)
            import datetime
            timestamp = datetime.datetime.now().strftime("%Y%m%d_%H%M%S")
            log_file = os.path.join(log_dir, f"test_timeout_{test_name.replace('.hex', '')}_{timestamp}.log")
            
            with open(log_file, 'w') as f:
                f.write(f"=== TEST TIMEOUT ===\n")
                f.write(f"Test: {test_name}\n")
                f.write(f"Timeout: 10 seconds\n")
                f.write(f"Likely causes:\n")
                f.write(f"  - Infinite loop in test code\n")
                f.write(f"  - Deadlock in pipeline\n")
                f.write(f"  - Test requires more time (increase timeout)\n")
            
            print(f"  \033[93m📝 Timeout log saved: {log_file}\033[0m\n")
        except Exception as e:
            print(f"{test_name:<45} | \033[91m❌ ERR \033[0m")
            failed_count += 1

    print("-" * 65)
    if failed_count == 0:
        log_success(f"Summary: {passed_count} Passed, 0 Failed")
    else:
        log_error(f"Summary: {passed_count} Passed, {failed_count} Failed")
        sys.exit(1)

def cmd_coverage(args):
    # 1. Build Coverage Simulator
    log("Building Coverage-Instrumented Simulator...")
    args.mode = "coverage"
    cmd_build(args)
    
    # 2. Generate Random Test Data
    # Use a safer count to avoid crashes (1000 instrs)
    log("Generating Random Test Vectors (Count=1000)...")
    sim_bin = os.path.join(BUILD_DIR, "sim_cov")
    rand_hex = os.path.join(BUILD_DIR, "random_cov.hex")
    gen_script = os.path.join(PROJECT_ROOT, "tests", "test_gen.py")
    
    run_cmd(f"python3 {gen_script} --out {rand_hex} --count 1000", silent=True)
    
    # 3. Run Simulation to collect data
    log("Running Simulation to collect coverage data...")
    try:
        run_cmd(f"{sim_bin} +TESTFILE={rand_hex}", silent=True)
    except SystemExit:
        log_error("Simulation failed/crashed during coverage collection.")
        return

    # 4. Generate Report
    cov_dat = os.path.join("logs", "coverage.dat")
    if not os.path.exists(cov_dat):
        log_error("Coverage data not found. Simulation might have failed to write it.")
        return

    log("Generating Coverage Report...")
    print("-" * 60)
    
    # Check if verilator_coverage exists
    if shutil.which("verilator_coverage"):
        try:
            # Create annotated source
            anno_dir = os.path.join("logs", "annotated")
            os.makedirs(anno_dir, exist_ok=True)
            
            # Generate Annotation
            cmd_anno = f"verilator_coverage --annotate {anno_dir} {cov_dat}"
            subprocess.check_call(cmd_anno, shell=True, stdout=subprocess.DEVNULL)
            
            # Generate Rank/Summary
            cmd_rank = f"verilator_coverage -rank {cov_dat}"
            rank_output = subprocess.check_output(cmd_rank, shell=True, text=True)
            
            print("\033[1mCoverage Summary:\033[0m")
            print(rank_output)
            
            print(f"✅ \033[92mCoverage Report Generated!\033[0m")
            print(f"   📂 Annotated Source Code: \033[96m{os.path.join(PROJECT_ROOT, anno_dir)}\033[0m")
            print(f"   👉 Open '{anno_dir}/VSoC_Core.v' to see line execution counts.")

        except subprocess.CalledProcessError as e:
            print(f"Error generating report: {e}")
    else:
        log_error("'verilator_coverage' tool not found in PATH.")
    
    print("-" * 60)

# --- Main Entry ---
def main():
    # Styled Help Formatter
    class RichHelpFormatter(argparse.RawTextHelpFormatter):
        pass

    description_text = """
\033[1mRV32I Core - Command Line Interface (CLI) Reference\033[0m
===================================================

\033[1mCOMMAND OVERVIEW\033[0m

  \033[93m1. CHECK SYSTEM\033[0m
     \033[1m./runner.py check\033[0m
     - Verifies installation of: Verilator, Make, G++, SDL2, Python3.

  \033[93m2. CLEAN WORKSPACE\033[0m
     \033[1m./runner.py clean\033[0m
     - Removes 'build/' directory and temporary compiled files.

   \033[93m3. BUILD SIMULATOR\033[0m
     \033[1m./runner.py build [--mode {headless|gui|coverage}]\033[0m
     - Compiles the Verilog core into a C++ simulator.
     - \033[96m--mode headless\033[0m : (Default) Fast simulation, no video output.
     - \033[96m--mode gui\033[0m      : Enable SDL2 window for VGA/Video output.
     - \033[96m--mode coverage\033[0m : Enable Verification Coverage (logs/coverage.dat).

  \033[93m4. RUN APPLICATION\033[0m
     \033[1m./runner.py run <file>\033[0m
     - Assembles and executes a RISC-V program.
     - \033[96m<file>\033[0m  : Path to assembly (.s) or machine code (.hex) file.
     - Note: GUI mode is auto-detected based on VRAM usage.

  \033[93m5. RUN TESTS\033[0m
     \033[1m./runner.py test [OPTIONS]\033[0m
     - Executes regression test suite (functionality + performance).
     - \033[96m--functionality\033[0m  : Run only functional correctness tests.
     - \033[96m--performance\033[0m    : Run only performance benchmarks.
     - \033[96m--count N\033[0m        : Number of random instructions (default: 100).
     - \033[96m--seed S\033[0m         : Seed for random generation (optional).
     - Note: If no filter specified, runs ALL tests.
  \033[93m6. COVERAGE REPORT\033[0m
     \033[1m./runner.py coverage\033[0m
     - Builds coverage binary, runs simulation, and generates report.
     - Saves annotated source code to 'logs/annotated/'.
"""

    epilog_text = """
\033[1mQUICK START EXAMPLES:\033[0m
  • Run the colors demo:       \033[96m./runner.py run app/colors.s\033[0m
  • Run all tests:             \033[96m./runner.py test\033[0m
  • Run functional tests only: \033[96m./runner.py test --functionality\033[0m
  • Run performance tests:     \033[96m./runner.py test --performance\033[0m
  • Generate Coverage:         \033[96m./runner.py coverage\033[0m
  • Clean and rebuild:         \033[96m./runner.py clean && ./runner.py build --mode gui\033[0m

Project: RV32I_Core
Maintainer: Ismail Melik
"""

    parser = argparse.ArgumentParser(
        description=description_text,
        epilog=epilog_text,
        formatter_class=RichHelpFormatter
    )
    subparsers = parser.add_subparsers(dest="command", help="Available commands")
    
    # Command: check
    p_check = subparsers.add_parser("check", help="Check system environment dependencies")
    
    # Command: clean
    p_clean = subparsers.add_parser("clean", help="Clean build directory and artifacts")
    
    # Command: build
    p_build = subparsers.add_parser("build", help="Build the simulator binary")
    p_build.add_argument("--mode", choices=["headless", "gui", "coverage"], default="headless", 
                        help="Select build target:\n  headless - Fast, no display (default)\n  gui      - SDL2 visualization\n  coverage - Verification with coverage")
    
    # Command: run
    p_run = subparsers.add_parser("run", help="Run a RISC-V application (.s or .hex)")
    p_run.add_argument("file", help="Path to the application assembly (.s) or hex (.hex) file")
    # p_run.add_argument("--gui", action="store_true", help="Launch in Graphical User Interface (GUI) mode") (Removed/Auto-detected)
    
    # Command: test
    p_test = subparsers.add_parser("test", help="Run the regression test suite")
    p_test.add_argument("--count", type=int, default=100, help="Number of random instructions (default: 100)")
    p_test.add_argument("--seed", type=int, help="Random seed for reproducibility")
    p_test.add_argument("--functionality", action="store_true", help="Run only functional tests")
    p_test.add_argument("--performance", action="store_true", help="Run only performance tests")
    
    # Command: coverage
    p_cov = subparsers.add_parser("coverage", help="Run & Generate Coverage Report")

    # Manually check for no args to print help, otherwise it does nothing
    if len(sys.argv) == 1:
        parser.print_help(sys.stderr)
        sys.exit(1)

    args = parser.parse_args()
    
    if args.command == "check":
        cmd_check(args)
    elif args.command == "clean":
        cmd_clean(args)
    elif args.command == "build":
        cmd_build(args)
    elif args.command == "run":
        cmd_run(args)
    elif args.command == "test":
        cmd_test(args)
    elif args.command == "coverage":
        cmd_coverage(args)
    else:
        parser.print_help()

if __name__ == "__main__":
    main()
