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
    print("\n" + "="*60)
    print("🔍 SYSTEM REQUIREMENTS CHECK")
    print("="*60)
    
    # Define dependencies with descriptions
    dependencies = [
        ("verilator", "Verilog HDL simulator"),
        ("make", "Build automation tool"),
        ("g++", "C++ compiler"),
        ("sdl2-config", "SDL2 library (for GUI)"),
        ("python3", "Python interpreter"),
    ]
    
    missing = []
    max_name_len = max(len(name) for name, _ in dependencies)
    
    # ANSI color codes
    GREEN = "\033[92m"
    RED = "\033[91m"
    YELLOW = "\033[93m"
    RESET = "\033[0m"
    
    for tool, description in dependencies:
        available = shutil.which(tool) is not None
        status = f"{GREEN}✅ Installed{RESET}" if available else f"{RED}❌ Missing{RESET}"
        print(f"  {tool:<{max_name_len}}  {status}  ({description})")
        
        if not available:
            missing.append(tool)
    
    print("="*60)
    
    if missing:
        print(f"\n{RED}❌ Missing dependencies: {', '.join(missing)}{RESET}")
        print(f"\n{YELLOW}Install missing tools before proceeding.{RESET}\n")
        sys.exit(1)
    else:
        print(f"\n{GREEN}✅ All dependencies satisfied!{RESET}\n")

# --- Commands ---
def cmd_check(args):
    check_env()

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
    
    # Trace mode check - only works with headless
    if args.trace and use_gui:
        log_error("Trace mode (--trace) is only supported with headless simulation.")
        log("Application requires GUI (VRAM usage detected). Cannot generate waveform.")
        sys.exit(1)
    
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
    
    # Prepare VCD path if trace enabled
    vcd_path = None
    if args.trace:
        import datetime
        timestamp = datetime.datetime.now().strftime("%Y%m%d_%H%M%S")
        app_name = os.path.splitext(os.path.basename(args.file))[0]
        vcd_filename = f"{app_name}_{timestamp}.vcd"
        
        waveform_dir = os.path.join(PROJECT_ROOT, "logs", "waveforms")
        os.makedirs(waveform_dir, exist_ok=True)
        
        vcd_path = os.path.join(waveform_dir, vcd_filename)
        log(f"Waveform will be saved to: {vcd_path}")
            
    # Run Simulation
    log(f"Launching simulation [{mode_str}] (Auto-Detected)...")
    
    # Clear old performance log if --perf enabled (prevents showing stale data)
    if args.perf:
        perf_log = os.path.join(PROJECT_ROOT, "logs", "perf_counters.txt")
        if os.path.exists(perf_log):
            os.remove(perf_log)
    
    # Build command with flags
    perf_flag = "+PERF_ENABLE" if args.perf else ""
    vcd_flag = f"+VCD={vcd_path}" if args.trace else ""
    cmd = f"{sim_bin} +TESTFILE={hex_path} {perf_flag} {vcd_flag}".strip()
    
    try:
        result = subprocess.run(cmd, shell=True, cwd=PROJECT_ROOT)
        
        # Show performance report if --perf enabled and simulation succeeded
        if args.perf and result.returncode == 0:
            perf_log = os.path.join(PROJECT_ROOT, "logs", "perf_counters.txt")
            if os.path.exists(perf_log):
                
                # Import and call performance_report
                sys.path.insert(0, TOOLS_DIR)
                from performance_report import generate_report
                
                try:
                    app_name = os.path.splitext(os.path.basename(args.file))[0]
                    generate_report(perf_file=perf_log, test_name=app_name)
                except Exception as e:
                    log_error(f"Report generation failed: {e}")
            else:
                log_error("Performance log not found. Make sure simulation completed successfully.")
        
        if result.returncode != 0:
            log_error("Simulation failed.")
            sys.exit(result.returncode)
        
        # Launch GTKWave if --view flag and trace was enabled
        if args.trace and args.view and vcd_path and os.path.exists(vcd_path):
            log("Launching GTKWave...")
            
            # Load GTKWave template (default: core_signals)
            template_dir = os.path.join(PROJECT_ROOT, "tb", "templates")
            template_name = args.template if args.template else "core_signals"
            template_file = f"{template_name}.gtkw"
            template_path = os.path.join(template_dir, template_file)
            
            if not os.path.exists(template_path):
                log(f"Warning: Template '{template_name}' not found. Opening without template.")
                template_path = None
            
            # Launch GTKWave
            try:
                if template_path:
                    subprocess.Popen(["gtkwave", vcd_path, "-a", template_path], 
                                   stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
                    log_success(f"GTKWave launched with template: {template_name}")
                else:
                    subprocess.Popen(["gtkwave", vcd_path],
                                   stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
                    log_success(f"GTKWave launched (no template)")
            except FileNotFoundError:
                log_error("GTKWave not found. Install with: sudo apt install gtkwave")
            except Exception as e:
                log_error(f"Failed to launch GTKWave: {e}")
        
        # Generate VCD analysis reports if --analyze flag
        if args.trace and args.analyze and vcd_path and os.path.exists(vcd_path):
            log("Generating VCD analysis reports...")
            
            # Parse analyze mode
            def parse_analyze_mode(mode_str):
                if mode_str == 'all':
                    return ['exec', 'pipeline', 'events', 'state']
                elif mode_str == 'minimal':
                    return ['exec', 'pipeline']
                elif mode_str == 'debug':
                    return ['pipeline', 'events']
                else:
                    # Custom comma-separated
                    return [x.strip() for x in mode_str.split(',')]
            
            # Create trace directory (matching VCD timestamp)
            vcd_name = os.path.splitext(os.path.basename(vcd_path))[0]  # e.g., "counter_loop_20251225_153851"
            trace_dir = os.path.join(PROJECT_ROOT, "logs", "traces", vcd_name)
            os.makedirs(trace_dir, exist_ok=True)
            
            # Import analyzer
            sys.path.insert(0, TOOLS_DIR)
            try:
                from vcd_analyzer import VCDAnalyzer
                
                analyzer = VCDAnalyzer(vcd_path)
                outputs = parse_analyze_mode(args.analyze)
                
                # Generate outputs
                for output_type in outputs:
                    output_file = os.path.join(trace_dir, f"{output_type}.txt")
                    try:
                        analyzer.generate(output_type, output_file)
                    except Exception as e:
                        log_error(f"Failed to generate {output_type}: {e}")
                
                log_success(f"Analysis reports: logs/traces/{vcd_name}/")
                
            except ImportError as e:
                log_error(f"Failed to import vcd_analyzer: {e}")
            except Exception as e:
                log_error(f"VCD analysis failed: {e}")
            
    except KeyboardInterrupt:
        print("\n")
        log("Simulation interrupted by user.")
        
        # Show performance report if --perf enabled even on interrupt
        if args.perf:
            perf_log = os.path.join(PROJECT_ROOT, "logs", "perf_counters.txt")
            if os.path.exists(perf_log):
                print("\n" + "="*60)
                log("Performance Report (interrupted):")
                print("="*60)
                
                sys.path.insert(0, TOOLS_DIR)
                from performance_report import generate_report
                
                try:
                    app_name = os.path.splitext(os.path.basename(args.file))[0]
                    generate_report(perf_file=perf_log, test_name=app_name)
                except Exception as e:
                    log_error(f"Report generation failed: {e}")

def generate_performance_summary(perf_results, args):
    """Generate and display/save performance summary table"""
    sys.path.insert(0, TOOLS_DIR)
    from performance_summary import generate_summary_table, save_report
    from regression_checker import save_baseline, check_regression
    
    # Generate summary table
    summary_text = generate_summary_table(perf_results, use_color=True)
    
    # Always display to terminal
    print(summary_text)
    
    # Save baseline if requested
    if args.save_baseline:
        baseline_path = save_baseline(perf_results)
        print(f"\n💾 Baseline saved to: {baseline_path}")
    
    # Check regression if requested
    if args.check_regression:
        report_lines, has_regression = check_regression(perf_results)
        for line in report_lines:
            print(line)
        
        if has_regression:
            # Use direct ANSI codes instead of Colors class
            print(f"\n\033[91m❌ Performance regression detected!\033[0m")
            print(f"   Consider investigating the changes or updating baseline if intentional.")
    
    # Collect verbose content if requested
    verbose_content = None
    if args.verbose:
        print(f"\n{Colors.BOLD}📋 DETAILED REPORTS{Colors.RESET}\n")
        # Note: Detailed reports already shown during test run if --verbose
        verbose_content = "(Detailed reports shown above during test execution)"
    
    # Save to file if requested
    if args.save is not None:
        save_path = None if args.save is True else args.save
        saved_file = save_report(summary_text, save_path, verbose_content)
        print(f"\n💾 Report saved to: {saved_file}")


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
        func_dir = os.path.join(PROJECT_ROOT, "tests", "functional")
        random_hex = os.path.join(func_dir, "random_corner_test.hex")
        gen_script = os.path.join(TOOLS_DIR, "random_instruction_test_gen.py")
        
        if os.path.exists(gen_script):
            seed_arg = f"--seed {args.seed}" if args.seed is not None else ""
            cmd_gen = f"python3 {gen_script} --out {random_hex} --count {args.count} {seed_arg}"
            
            try:
                subprocess.check_call(cmd_gen, shell=True, cwd=PROJECT_ROOT, stdout=subprocess.DEVNULL)
                # No need to add to tests list - will be picked up with other hex files
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
        # Performance Benchmarks
        perf_tests = [
            os.path.join(PROJECT_ROOT, "tests", "performance", "array_sum.s"),
            os.path.join(PROJECT_ROOT, "tests", "performance", "memcpy.s"),
            os.path.join(PROJECT_ROOT, "tests", "performance", "matrix_transpose.s"),
            os.path.join(PROJECT_ROOT, "tests", "performance", "binary_search.s"),
            os.path.join(PROJECT_ROOT, "tests", "performance", "bubble_sort.s"),
        ]
        
        assembler_script = os.path.join(TOOLS_DIR, "assembler.py")
        for asm_file in perf_tests:
            if os.path.exists(asm_file):
                # Assemble to hex in BUILD_DIR
                hex_name = os.path.basename(asm_file).replace(".s", ".hex")
                hex_path = os.path.join(BUILD_DIR, hex_name)
                
                try:
                    subprocess.check_call(
                        f"python3 {assembler_script} {asm_file} {hex_path}",
                        shell=True, cwd=PROJECT_ROOT, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL
                    )
                    tests.append((os.path.basename(hex_path), hex_path, "performance"))
                except subprocess.CalledProcessError:
                    log_error(f"Failed to assemble performance test {os.path.basename(asm_file)}")
            else:
                log_error(f"Performance test file not found: {asm_file}")

    if not tests:
        log_error("No tests found to run.")
        return

    passed_count = 0
    failed_count = 0
    perf_results = {}  # NEW: Collect performance results for summary table
    
    sim_bin = os.path.join(BUILD_DIR, "sim_headless")
    
    for test_name, hex_path, category in tests:
        try:
            # Build command with performance flag for performance tests
            perf_flag = "+PERF_ENABLE" if (category == "performance" or args.perf) else ""
            cmd = f"{sim_bin} +TESTFILE={hex_path} {perf_flag}".strip()
            
            result = subprocess.run(
                cmd,
                shell=True,
                cwd=PROJECT_ROOT,
                capture_output=True,
                text=True,
                timeout=30
            )
            output = result.stdout + result.stderr
            
            # Check for success (exit code 0)
            if result.returncode == 0 and "PASSED" in output:
                print(f"{test_name:<45} | \033[92m✅ PASS\033[0m")
                passed_count += 1
                
                # Collect performance data for summary table (performance category only)
                if category == "performance":
                    perf_log = os.path.join(PROJECT_ROOT, "logs", "perf_counters.txt")
                    if os.path.exists(perf_log):
                        sys.path.insert(0, TOOLS_DIR)
                        from performance_summary import parse_perf_file
                        metrics = parse_perf_file(perf_log)
                        benchmark_name = test_name.replace('.hex', '')
                        perf_results[benchmark_name] = ('PASS', metrics)
                
                # Generate performance report if --perf enabled for functional tests
                # OR always for performance category tests (but only if NOT in summary mode)
                if (args.perf and category == "functional") or (category == "performance" and args.verbose):
                    perf_log = os.path.join(PROJECT_ROOT, "logs", "perf_counters.txt")
                    if os.path.exists(perf_log):
                        sys.path.insert(0, TOOLS_DIR)
                        from performance_report import generate_report
                        
                        # Display compact report
                        print(f"   📊 Performance Metrics:")
                        try:
                            generate_report(perf_file=perf_log, test_name=test_name.replace('.hex', ''))
                        except Exception as e:
                            print(f"   ⚠️  Report generation failed: {e}")
            else:
                print(f"{test_name:<45} | \033[91m❌ FAIL\033[0m")
                failed_count += 1
                
                # Store FAIL status for performance tests too
                if category == "performance":
                    benchmark_name = test_name.replace('.hex', '')
                    perf_results[benchmark_name] = ('FAIL', None)
                
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
    
    # Generate performance summary table if performance tests were run
    if run_performance and passed_count > 0:
        print("\n")  # Extra spacing
        generate_performance_summary(perf_results, args)
    
    if failed_count > 0:
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

  \033[93m1. CHECK DEPENDENCIES\033[0m
     \033[1m./runner.py env\033[0m
     - Verifies all system dependencies (Verilator, Make, SDL2, etc.).

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
     \033[1m./runner.py run <file> [OPTIONS]\033[0m
     - Assembles and executes a RISC-V program.
     - \033[96m<file>\033[0m  : Path to assembly (.s) or machine code (.hex) file.
     - \033[96m--perf\033[0m : Enable performance monitoring and show report.
     - \033[96m--trace\033[0m : Generate VCD waveform (logs/waveforms/<name>_<timestamp>.vcd).
     - \033[96m--analyze <MODE>\033[0m : VCD text analysis (requires --trace).
         Modes: all (4 traces), minimal (exec+pipeline), debug (pipeline+events)
         Custom: exec,pipeline,events,state
         Output: logs/traces/<name>_<timestamp>/
     - \033[96m--view\033[0m  : Auto-launch GTKWave after trace generation (requires --trace).
     - \033[96m--template <name>\033[0m : Use GTKWave template from tb/templates/<name>.gtkw
       Default template: core_signals
     - Note: GUI mode is auto-detected based on VRAM usage.

  \033[93m5. RUN TESTS\033[0m
     \033[1m./runner.py test [OPTIONS]\033[0m
     - Executes regression test suite (functionality + performance).
     - \033[96m--functionality\033[0m  : Run only functional correctness tests.
     - \033[96m--performance\033[0m    : Run only performance benchmarks (with summary table).
     - \033[96m--verbose\033[0m        : Show detailed per-benchmark performance reports.
     - \033[96m--save [PATH]\033[0m    : Save performance summary to file (auto-generates filename if no path).
     - \033[96m--save-baseline\033[0m  : Save current performance as baseline (expected.json).
     - \033[96m--check-regression\033[0m : Compare against baseline and report improvements/regressions.
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
    
    # Command: env
    p_env = subparsers.add_parser("env", help="Check system environment dependencies")
    p_env.set_defaults(func=cmd_check)
    
    # Command: clean
    p_clean = subparsers.add_parser("clean", help="Clean build directory and artifacts")
    
    # Command: build
    p_build = subparsers.add_parser("build", help="Build the simulator binary")
    p_build.add_argument("--mode", choices=["headless", "gui", "coverage"], default="headless", 
                        help="Select build target:\n  headless - Fast, no display (default)\n  gui      - SDL2 visualization\n  coverage - Verification with coverage")
    
    # Command: run
    p_run = subparsers.add_parser("run", help="Run a RISC-V application (.s or .hex)")
    p_run.add_argument("file", help="Path to the application assembly (.s) or hex (.hex) file")
    p_run.add_argument("--perf", action="store_true", help="Enable performance monitoring and show report after execution")
    p_run.add_argument("--trace", action="store_true", help="Enable VCD waveform generation (only for headless mode)")
    p_run.add_argument("--analyze", type=str, default=None,
                      help="""VCD analysis output types (requires --trace):
  all      - All 4 traces (exec+pipeline+events+state)
  minimal  - Exec + Pipeline traces only  
  debug    - Pipeline + Events (for bug hunting)
  Custom combination: exec,pipeline,events,state""")
    p_run.add_argument("--view", action="store_true", help="Auto-launch GTKWave after trace generation (requires --trace)")
    p_run.add_argument("--template", type=str, help="GTKWave template name (e.g., 'core_signals' loads templates/core_signals.gtkw)")
    # p_run.add_argument("--gui", action="store_true", help="Launch in Graphical User Interface (GUI) mode") (Removed/Auto-detected)
    
    # Command: test
    p_test = subparsers.add_parser("test", help="Run the regression test suite")
    p_test.add_argument("--count", type=int, default=100, help="Number of random instructions (default: 100)")
    p_test.add_argument("--seed", type=int, help="Random seed for reproducibility")
    p_test.add_argument("--functionality", action="store_true", help="Run only functional tests")
    p_test.add_argument("--performance", action="store_true", help="Run only performance tests")
    p_test.add_argument("--perf", action="store_true", help="Enable performance monitoring and generate report")
    p_test.add_argument("--verbose", action="store_true", help="Show detailed performance reports")
    p_test.add_argument("--save", nargs='?', const=True, default=None, metavar='PATH', 
                       help="Save performance report to file (auto-generated name if no path given)")
    p_test.add_argument("--save-baseline", action="store_true", help="Save current performance results as baseline (expected.json)")
    p_test.add_argument("--check-regression", action="store_true", help="Compare performance against baseline and report regressions")
    
    # Command: coverage
    p_cov = subparsers.add_parser("coverage", help="Run & Generate Coverage Report")

    # Manually check for no args to print help, otherwise it does nothing
    if len(sys.argv) == 1:
        parser.print_help(sys.stderr)
        sys.exit(1)

    args = parser.parse_args()
    
    if args.command == "env":
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
