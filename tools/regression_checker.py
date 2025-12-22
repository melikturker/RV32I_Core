#!/usr/bin/env python3
"""
Performance Regression Checker
Compares current benchmark results against baseline (expected.json)
Reports improvements and regressions with color-coded deltas
"""

import json
import os

# ANSI color codes
class Colors:
    GREEN = '\033[92m'
    RED = '\033[91m'
    YELLOW = '\033[93m'
    BLUE = '\033[94m'
    CYAN = '\033[96m'
    BOLD = '\033[1m'
    RESET = '\033[0m'

def save_baseline(perf_results, baseline_path="tests/performance/expected.json"):
    """
    Save current performance results as baseline
    perf_results: dict of {benchmark_name: (status, metrics_dict)}
    """
    baseline = {}
    
    for bench_name, (status, metrics) in perf_results.items():
        if status == 'PASS' and metrics:
            baseline[bench_name] = {
                'ipc': metrics['ipc'],
                'cycles': metrics['cycles'],
                'instructions': metrics['instructions'],
                'pipeline_util': metrics['pipeline_util'],
                'stall_rate': metrics['stall_rate'],
                'branch_rate': metrics['branch_rate'],
                'jump_rate': metrics['jump_rate']
            }
    
    # Define tolerance thresholds
    baseline['_tolerances'] = {
        'ipc': 0.02,           # ±2%
        'cycles': 0.05,        # ±5%
        'instructions': 0.01,  # ±1% (should be very stable)
        'pipeline_util': 0.02, # ±2%
        'stall_rate': 0.01,    # ±1 percentage point
        'branch_rate': 0.01,   # ±1%
        'jump_rate': 0.01      # ±1%
    }
    
    # Create directory if needed
    os.makedirs(os.path.dirname(baseline_path), exist_ok=True)
    
    # Write JSON
    with open(baseline_path, 'w') as f:
        json.dump(baseline, f, indent=2)
    
    return baseline_path

def check_regression(perf_results, baseline_path="tests/performance/expected.json"):
    """
    Compare current results against baseline
    Returns: (report_lines, has_regression)
    """
    # Load baseline
    if not os.path.exists(baseline_path):
        return ([f"{Colors.YELLOW}⚠️  No baseline found at {baseline_path}{Colors.RESET}",
                 f"   Run with --save-baseline to create one."], False)
    
    with open(baseline_path, 'r') as f:
        baseline = json.load(f)
    
    tolerances = baseline.get('_tolerances', {})
    
    # Compare each benchmark
    report = []
    report.append(f"\n{Colors.BOLD}📊 REGRESSION CHECK REPORT{Colors.RESET}")
    
    # Calculate actual table width based on columns (now with 2 change columns)
    table_width = 18 + 3 + 14 + 3 + 10 + 3 + 10 + 3 + 12 + 3 + 10 + 3 + 15  # sum of column widths + separators
    
    report.append("=" * table_width)
    header = f"{'Benchmark':<18} | {'Metric':<14} | {'Expected':>10} | {'Current':>10} | {'Abs Change':>12} | {'Rel %':>10} | {'Status':<15}"
    report.append(header)
    report.append("-" * table_width)
    
    improved_count = 0
    regressed_count = 0
    ok_count = 0
    has_regression = False
    
    for bench_name, (status, metrics) in perf_results.items():
        if status != 'PASS' or not metrics or bench_name not in baseline:
            continue
        
        expected = baseline[bench_name]
        
        # Check key metrics
        checks = [
            ('IPC', 'ipc', True),               # Higher is better
            ('Pipeline Util', 'pipeline_util', True),  # Higher is better
            ('Stall Rate', 'stall_rate', False),       # Lower is better
            ('Cycles', 'cycles', False),               # Lower is better
        ]
        
        for metric_name, metric_key, higher_is_better in checks:
            if metric_key not in expected or metric_key not in metrics:
                continue
            
            exp_val = expected[metric_key]
            cur_val = metrics[metric_key]
            delta_abs = cur_val - exp_val
            delta_pct = (delta_abs / exp_val * 100) if exp_val != 0 else 0
            
            # Determine tolerance
            tolerance = tolerances.get(metric_key, 0.02)
            if metric_key in ['stall_rate', 'branch_rate', 'jump_rate']:
                # Absolute tolerance for rates
                within_tolerance = abs(delta_abs) <= tolerance
            else:
                # Percentage tolerance
                within_tolerance = abs(delta_pct) <= (tolerance * 100)
            
            # Classify change
            if within_tolerance:
                status_str = f"{Colors.RESET}✅ OK{Colors.RESET}"
                ok_count += 1
            elif (higher_is_better and delta_abs > 0) or (not higher_is_better and delta_abs < 0):
                status_str = f"{Colors.GREEN}✅ IMPROVED{Colors.RESET}"
                improved_count += 1
            else:
                status_str = f"{Colors.RED}⚠️  REGRESSED{Colors.RESET}"
                regressed_count += 1
                has_regression = True
            
            # Format values with consistent decimals
            if metric_key in ['ipc', 'pipeline_util', 'stall_rate', 'branch_rate', 'jump_rate']:
                if metric_key == 'ipc':
                    exp_str = f"{exp_val:.3f}"
                    cur_str = f"{cur_val:.3f}"
                    abs_change_str = f"{delta_abs:+.3f}"  # Absolute IPC change
                else:
                    exp_str = f"{exp_val*100:.2f}%"
                    cur_str = f"{cur_val*100:.2f}%"
                    abs_change_str = f"{delta_abs*100:+.2f}%"  # Absolute percentage point change
                
                rel_change_str = f"{delta_pct:+.1f}%"  # Relative percentage change
            else:
                exp_str = f"{int(exp_val):,}"
                cur_str = f"{int(cur_val):,}"
                abs_change_str = f"{int(delta_abs):+,}"
                rel_change_str = f"{delta_pct:+.1f}%"
            
            # Color changes
            if within_tolerance:
                abs_colored = abs_change_str
                rel_colored = rel_change_str
            elif (higher_is_better and delta_abs > 0) or (not higher_is_better and delta_abs < 0):
                abs_colored = f"{Colors.GREEN}{abs_change_str}{Colors.RESET}"
                rel_colored = f"{Colors.GREEN}{rel_change_str}{Colors.RESET}"
            else:
                abs_colored = f"{Colors.RED}{abs_change_str}{Colors.RESET}"
                rel_colored = f"{Colors.RED}{rel_change_str}{Colors.RESET}"
            
            row = f"{bench_name:<18} | {metric_name:<14} | {exp_str:>10} | {cur_str:>10} | {abs_colored:>12} | {rel_colored:>10} | {status_str:<15}"
            report.append(row)
    
    report.append("=" * table_width)
    summary = f"Summary: {improved_count} Improved, {regressed_count} Regressed, {ok_count} OK"
    if regressed_count > 0:
        report.append(f"{Colors.RED}{summary}{Colors.RESET}")
    elif improved_count > 0:
        report.append(f"{Colors.GREEN}{summary}{Colors.RESET}")
    else:
        report.append(summary)
    
    return (report, has_regression)

if __name__ == "__main__":
    # Test with dummy data
    test_results = {
        'array_sum': ('PASS', {
            'ipc': 0.688, 'cycles': 262153, 'instructions': 180236,
            'pipeline_util': 0.813, 'stall_rate': 0.062
        })
    }
    
    # Save baseline
    save_baseline(test_results, "test_baseline.json")
    
    # Check (should be OK)
    report, has_reg = check_regression(test_results, "test_baseline.json")
    for line in report:
        print(line)
