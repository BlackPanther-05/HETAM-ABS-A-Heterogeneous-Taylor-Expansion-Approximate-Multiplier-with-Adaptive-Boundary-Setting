#!/usr/bin/env python3
"""
run_approx_sim.py
=================
Automates iverilog simulation of both approx_t and approx_t_hetero designs
with VCD waveform generation for power analysis.

DESIGNS SUPPORTED:
  1. approx_t (BASE)
     - RTL : RTL/
     - Levels: 0-5 (6 levels)
     - Widths: 8, 24
     - Total: 2 widths x 6 levels = 12 runs

  2. approx_t_hetero (PROPOSED)
     - RTL : RTL_proposed/
     - Levels: 0-2 (3 levels)
     - Widths: 8, 24
     - Total: 2 widths x 3 levels = 6 runs

OUTPUT STRUCTURE (per design):
  Simulation_Results/
    ├── approx_t/              <- CSV files for base approx_t
    └── approx_t_hetero/       <- CSV files for proposed approx_t_hetero
  
  vcd/                         <- TOP-LEVEL VCD FOLDER
    ├── approx_t/              <- VCD for base design
    │   ├── approx_t_w8_level0.vcd
    │   └── ...
    └── approx_t_hetero/       <- VCD for proposed design
        ├── approx_t_hetero_w8_level0.vcd
        └── ...

PROJECT LAYOUT (run from PROJECT ROOT):

  project_root/
  ├── run_approx_sim.py                        <- THIS SCRIPT
  ├── RTL/                                     <- Base multiplier
  │   ├── approx_t.v
  │   └── bit_mask_sel.v
  ├── RTL_proposed/                            <- Hetero multiplier
  │   ├── approx_t_hetero.v
  │   └── bit_mask_sel.v
  ├── Test_Bench/
  │   └── approx_t/
  │       └── tb_approx_t.v
  ├── Test_Bench_proposed/
  │   └── approx_t_hetero/
  │       └── tb_approx_t_hetero.v
  ├── Simulation_Results/
  │   ├── approx_t/             <- CSV files (auto-created)
  │   └── approx_t_hetero/      <- CSV files (auto-created)
  └── vcd/                       <- TOP-LEVEL VCD (auto-created)
      ├── approx_t/
      └── approx_t_hetero/

FOR EACH (width, level) PAIR:
  1.  Creates all output directories for design if missing
  2.  Compiles RTL + testbench via iverilog (-P<tb_name>.WIDTH=W)
      One binary per WIDTH per design, reused across all levels for that design
  3.  Runs vvp with +level=L +width=W from appropriate Test_Bench directory
      (so ../../ relative paths inside $fopen/$dumpfile resolve correctly)
  4.  Verifies the VCD was produced and is non-empty
  5. Verifies CSV and VCD files exist and are non-empty

TOTAL RUNS: (2 widths x 6 levels for approx_t) + (2 widths x 3 levels for approx_t_hetero) = 18 pairs

USAGE:
  python3 run_approx_sim.py                    # all designs, all widths, all levels
  python3 run_approx_sim.py --designs base     # base (approx_t) only
  python3 run_approx_sim.py --designs proposed # proposed (approx_t_hetero) only
  python3 run_approx_sim.py --widths 8         # WIDTH=8 only
  python3 run_approx_sim.py --widths 24        # WIDTH=24 only
  python3 run_approx_sim.py --designs base --widths 8 24 --levels 0 3 5

REQUIREMENTS:
  iverilog / vvp  ->  sudo apt install iverilog
"""

import argparse
import os
import shutil
import subprocess
import sys
import time

# -----------------------------------------------------------------------
# Design Configurations
# Each design defines RTL location, testbench, and supported levels/widths
# -----------------------------------------------------------------------
DESIGNS = {
    "base": {
        "name": "approx_t",           # Short name for outputs
        "rtl_dir": "RTL",             # RTL source directory
        "tb_dir": os.path.join("Test_Bench", "approx_t"),    # Testbench directory
        "tb_file": "tb_approx_t.v",   # Testbench file
        "tb_param": "tb_approx_t",    # Module name for parameter override (-P)
        "rtl_sources": ["approx_t.v", "bit_mask_sel.v"],  # RTL files
        "levels": list(range(6)),     # Levels 0-5

    },
    "proposed": {
        "name": "approx_t_hetero",    # Short name for outputs
        "rtl_dir": "RTL_proposed",    # RTL source directory
        "tb_dir": os.path.join("Test_Bench_proposed", "approx_t_hetero"),  # Testbench directory
        "tb_file": "tb_approx_t_hetero.v",  # Testbench file
        "tb_param": "tb_approx_t_hetero",   # Module name for parameter override (-P)
        "rtl_sources": ["approx_t_hetero.v", "bit_mask_sel.v"],  # RTL files
        "levels": list(range(0, 3)),  # Levels 0-2

    }
}

# Common widths for all designs
ALL_WIDTHS = [8, 24]

# Top-level VCD folder
VCD_TOP_DIR = "vcd"

# -----------------------------------------------------------------------
# Terminal colours
# -----------------------------------------------------------------------
_COL = sys.platform != "win32" and sys.stdout.isatty()
def _c(code): return f"\033[{code}m" if _COL else ""
GREEN  = _c("92"); RED    = _c("91"); YELLOW = _c("93")
CYAN   = _c("96"); BOLD   = _c("1");  RESET  = _c("0")

def log(msg, color=""):
    print(f"{color}{msg}{RESET}", flush=True)

# -----------------------------------------------------------------------
# Utility helpers
# -----------------------------------------------------------------------
def check_tool(name):
    return shutil.which(name) is not None


def run_cmd(cmd, cwd=None):
    """
    Run command, stream output, return (returncode, stdout, stderr).
    Prints all output lines to console with colour coding.
    """
    log(f"  $ {' '.join(str(c) for c in cmd)}", CYAN)
    result = subprocess.run(
        cmd, cwd=cwd,
        stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True
    )
    for line in result.stdout.strip().splitlines():
        log(f"    {line}")
    for line in result.stderr.strip().splitlines():
        color = RED if result.returncode != 0 else YELLOW
        log(f"    {line}", color)
    return result.returncode, result.stdout, result.stderr


def make_dirs(root, designs):
    """Create all required output directories for specified designs."""
    for design_key in designs:
        design = DESIGNS[design_key]
        
        # CSV directory under Simulation_Results
        csv_dir = os.path.join(root, "Simulation_Results", design["name"])
        os.makedirs(csv_dir, exist_ok=True)
        log(f"  [DIR] {os.path.relpath(csv_dir, root)}/", GREEN)
        
        # VCD directory under top-level vcd/ folder
        vcd_dir = os.path.join(root, VCD_TOP_DIR, design["name"])
        os.makedirs(vcd_dir, exist_ok=True)
        log(f"  [DIR] {os.path.relpath(vcd_dir, root)}/", GREEN)
        
        # Testbench directory
        tb_dir = os.path.join(root, design["tb_dir"])
        os.makedirs(tb_dir, exist_ok=True)
        log(f"  [DIR] {os.path.relpath(tb_dir, root)}/", GREEN)


def verify_sources(root, designs):
    """Return list of missing source files for all specified designs."""
    missing = []
    for design_key in designs:
        design = DESIGNS[design_key]
        
        # Check RTL sources
        for src in design["rtl_sources"]:
            p = os.path.join(root, design["rtl_dir"], src)
            if not os.path.isfile(p):
                missing.append(os.path.relpath(p, root))
        
        # Check testbench
        tb = os.path.join(root, design["tb_dir"], design["tb_file"])
        if not os.path.isfile(tb):
            missing.append(os.path.relpath(tb, root))
    
    return missing


# -----------------------------------------------------------------------
# Per-width compilation (per design)
# -----------------------------------------------------------------------
def compile_design(design_key, width, root):
    """
    Compile RTL + testbench for a specific design and WIDTH.
    One binary per WIDTH per design — reused across all levels for that design.
    Binary placed at: <TestBench>/sim_wW
    Parameter override: -P<design.tb_param>.WIDTH=W
    Returns (success: bool, binary_path: str).
    """
    design = DESIGNS[design_key]
    
    binary  = os.path.join(root, design["tb_dir"], f"sim_w{width}")
    sources = [os.path.join(root, design["rtl_dir"], s) for s in design["rtl_sources"]]
    sources += [os.path.join(root, design["tb_dir"], design["tb_file"])]

    cmd = [
        "iverilog", "-g2012", "-Wall",
        f"-P{design['tb_param']}.WIDTH={width}",
        "-o", binary
    ] + sources

    log(f"\n  Compiling {design['name']} for WIDTH={width}...", BOLD)
    rc, _, _ = run_cmd(cmd)
    if rc != 0:
        log(f"  [FAIL] Compile failed for {design['name']} WIDTH={width}", RED)
        return False, binary
    log(f"  [OK]   Binary -> {os.path.relpath(binary, root)}", GREEN)
    return True, binary


# -----------------------------------------------------------------------
# Per-(width, level) simulation (per design)
# -----------------------------------------------------------------------
def simulate(design_key, width, level, binary, root):
    """
    Run vvp from <design.tb_dir> so that the ../../ relative paths
    inside $fopen and $dumpfile resolve correctly.
    Passes +level=L +width=W as runtime plusargs.
    Returns success bool.
    """
    design = DESIGNS[design_key]
    tb_run_dir = os.path.join(root, design["tb_dir"])
    cmd = ["vvp", binary, f"+level={level}", f"+width={width}"]
    rc, _, _ = run_cmd(cmd, cwd=tb_run_dir)
    if rc != 0:
        log(f"  [FAIL] Simulation failed  {design['name']} WIDTH={width} level={level}", RED)
        return False
    log(f"  [OK]   Simulation done    {design['name']} WIDTH={width} level={level}", GREEN)
    return True


def verify_vcd(design_key, width, level, root):
    """
    Check VCD exists and is non-empty.
    A missing or empty VCD means the simulation did not produce valid output.
    VCD stored in vcd/<design_name>/
    Returns (success: bool, vcd_path: str).
    """
    design = DESIGNS[design_key]
    vcd_path = os.path.join(root, VCD_TOP_DIR, design["name"], 
                            f"{design['name']}_w{width}_level{level}.vcd")
    rel      = os.path.relpath(vcd_path, root)

    if not os.path.isfile(vcd_path):
        log(f"  [FAIL] VCD not found: {rel}", RED)
        log(f"         The simulation did not write the VCD file.", RED)
        log(f"         Check that {os.path.relpath(os.path.dirname(vcd_path), root)}/ directory exists and is writable.", RED)
        return False, vcd_path

    size = os.path.getsize(vcd_path)
    if size == 0:
        log(f"  [FAIL] VCD is empty (0 bytes): {rel}", RED)
        log(f"         The VCD was created but $dumpflush may have failed.", RED)
        return False, vcd_path

    log(f"  [OK]   VCD verified: {rel}  ({size:,} bytes)", GREEN)
    return True, vcd_path



# -----------------------------------------------------------------------
# Final output verification (per design)
# -----------------------------------------------------------------------
def verify_outputs(design_key, width, level, root):
    """
    Verify CSV and VCD files exist and are non-empty.
    Returns True only if all files are present and non-empty.
    """
    design = DESIGNS[design_key]
    checks = {
        "CSV" : os.path.join(root, "Simulation_Results", design["name"], 
                            f"results_w{width}_level{level}.csv"),
        "VCD" : os.path.join(root, VCD_TOP_DIR, design["name"], 
                            f"{design['name']}_w{width}_level{level}.vcd"),
    }
    all_ok = True
    for label, path in checks.items():
        rel = os.path.relpath(path, root)
        if os.path.isfile(path) and os.path.getsize(path) > 0:
            size = os.path.getsize(path)
            log(f"  [OK]   {label:4s}: {rel}  ({size:,} bytes)", GREEN)
        else:

            log(f"  [FAIL] {label:4s}: {rel}  (missing or empty)", RED)
            all_ok = False
    return all_ok


# -----------------------------------------------------------------------
# Main
# -----------------------------------------------------------------------
def main():
    parser = argparse.ArgumentParser(
        description="Run approx_t and approx_t_hetero simulations with VCD waveform generation.",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=__doc__
    )
    parser.add_argument(
        "--designs", nargs="+", type=str, choices=list(DESIGNS.keys()), 
        default=list(DESIGNS.keys()),
        metavar="D", help="Designs to simulate: base, proposed, or both (default: both)"
    )
    parser.add_argument(
        "--widths", nargs="+", type=int, default=ALL_WIDTHS,
        metavar="W", help="Widths to simulate (default: 8 24)"
    )
    parser.add_argument(
        "--levels", nargs="+", type=int, default=None,
        metavar="L", help="Levels to simulate (default: all levels for each design: base 0-5, proposed 0-2)"
    )
    args = parser.parse_args()

    # Validate design arguments
    for d in args.designs:
        if d not in DESIGNS:
            log(f"ERROR: Invalid design '{d}'. Must be: {', '.join(DESIGNS.keys())}", RED)
            sys.exit(1)

    # Validate width arguments
    for w in args.widths:
        if w not in ALL_WIDTHS:
            log(f"ERROR: Invalid width {w}. Must be 8 or 24.", RED)
            sys.exit(1)

    root = os.path.dirname(os.path.abspath(__file__))

    # ------------------------------------------------------------------
    log(f"\n{'='*70}")
    log("  Approximate Multiplier Simulation Runner (both approx_t & approx_t_hetero)", BOLD + CYAN)
    log(f"{'='*70}")
    log(f"  Project root : {root}")
    log(f"  Designs      : {', '.join([DESIGNS[d]['name'] for d in args.designs])}")
    for design_key in args.designs:
        design = DESIGNS[design_key]
        design_levels = args.levels if args.levels else design["levels"]
        log(f"    {design['name']:20s}: {design['rtl_dir']:20s} | Levels: {design_levels}")
    log(f"  Widths       : {args.widths}")
    log(f"  CSV output   : Simulation_Results/<design>/")
    log(f"  VCD output   : {VCD_TOP_DIR}/<design>/")
    total_pairs = sum(len(args.widths) * len(args.levels if args.levels else DESIGNS[d]["levels"]) for d in args.designs)
    log(f"  Total pairs  : {total_pairs}")
    log(f"{'='*70}\n")

    # Tool checks — hard fail if iverilog/vvp missing
    missing_tools = []
    if not check_tool("iverilog"):
        missing_tools.append("iverilog  (sudo apt install iverilog)")
    if not check_tool("vvp"):
        missing_tools.append("vvp       (sudo apt install iverilog)")
    if missing_tools:
        log("ERROR: Required tools not found:", RED)
        for t in missing_tools:
            log(f"  {t}", RED)
        sys.exit(1)

    log(f"[OK] iverilog  : {shutil.which('iverilog')}", GREEN)
    log(f"[OK] vvp       : {shutil.which('vvp')}", GREEN)
    print()

    # Create all required directories
    log("Creating output directories...", BOLD)
    make_dirs(root, args.designs)
    print()

    # Verify all source files are present
    missing = verify_sources(root, args.designs)
    if missing:
        log("ERROR: Missing source files:", RED)
        for m in missing:
            log(f"  {m}", RED)
        sys.exit(1)
    log("[OK] All source files present.\n", GREEN)

    # ==================================================================
    # Main loop: DESIGN (outer) -> WIDTH (middle) -> level (inner)
    # ==================================================================
    results     = {}       # key: (design_key, width, level) -> status string
    total_start = time.time()

    for design_key in args.designs:
        design = DESIGNS[design_key]
        design_levels = args.levels if args.levels else design["levels"]
        
        # Validate design-specific levels
        if args.levels:
            for lvl in design_levels:
                if lvl not in design["levels"]:
                    log(f"ERROR: Invalid level {lvl} for '{design['name']}'. Must be 0-{max(design['levels'])}.", RED)
                    sys.exit(1)

        log(f"\n{'='*70}")
        log(f"  DESIGN: {design['name']}", BOLD + CYAN)
        log(f"{'='*70}")

        for width in args.widths:

            log(f"\n  {'─'*66}")
            log(f"  {design['name']} | WIDTH = {width}", BOLD)
            log(f"  {'─'*66}")

            # ---- One compile per WIDTH per DESIGN ----
            compile_ok, binary = compile_design(design_key, width, root)
            if not compile_ok:
                for lvl in design_levels:
                    results[(design_key, width, lvl)] = "COMPILE_FAILED"
                print()
                continue

            # ---- One simulate per (width, level) ----
            for level in design_levels:
                log(f"\n    {design['name']} WIDTH={width}  LEVEL={level}", BOLD)
                t0 = time.time()

                # Step 1: Simulate -> writes CSV + VCD
                sim_ok = simulate(design_key, width, level, binary, root)
                if not sim_ok:
                    results[(design_key, width, level)] = "SIM_FAILED"
                    continue

                # Step 2: Verify VCD 
                vcd_ok, vcd_path = verify_vcd(design_key, width, level, root)
                if not vcd_ok:
                    results[(design_key, width, level)] = "VCD_MISSING"
                    continue
                
                # Step 3: Verify all outputs
                all_ok  = verify_outputs(design_key, width, level, root)
                elapsed = time.time() - t0

                if all_ok:
                    results[(design_key, width, level)] = f"OK ({elapsed:.1f}s)"
                else:
                    results[(design_key, width, level)] = f"OUTPUT_MISSING ({elapsed:.1f}s)"

            print()

    # ==================================================================
    # Final Summary
    # ==================================================================
    total_elapsed = time.time() - total_start
    log(f"\n{'='*70}")
    log("  FINAL SUMMARY", BOLD + CYAN)
    log(f"{'='*70}")

    all_ok = True
    for design_key in args.designs:
        design = DESIGNS[design_key]
        design_levels = args.levels if args.levels else design["levels"]
        
        log(f"\n  {design['name']}:", BOLD)
        for width in args.widths:
            log(f"    WIDTH={width}:")
            for level in design_levels:
                status = results.get((design_key, width, level), "NOT_RUN")
                color  = GREEN if status.startswith("OK") else RED
                log(f"      Level {level}: {status}", color)
                if not status.startswith("OK"):
                    all_ok = False

    log(f"\n  Total time : {total_elapsed:.1f}s")
    log(f"\n  Output locations:")
    for design_key in args.designs:
        design = DESIGNS[design_key]
        log(f"    {design['name']}:")
        log(f"      CSV : {os.path.join(root, 'Simulation_Results', design['name'])}/results_wW_levelL.csv")
        log(f"      VCD : {os.path.join(root, VCD_TOP_DIR, design['name'])}/{design['name']}_wW_levelL.vcd")
    log(f"{'='*70}\n")

    if not all_ok:
        sys.exit(1)


if __name__ == "__main__":
    main()
