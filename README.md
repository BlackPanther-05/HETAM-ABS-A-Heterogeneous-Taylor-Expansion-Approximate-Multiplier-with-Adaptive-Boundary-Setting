# HETAM-ABS: Heterogeneous Taylor-Expansion Approximate Multiplier with Adaptive Boundary Setting

A comprehensive RTL and simulation framework for evaluating approximate multiplier designs.

**Status**: Production-ready | **Language**: Verilog + Python

---

## 📋 Table of Contents

- [Project Overview](#project-overview)
- [Directory Structure](#directory-structure)
- [Prerequisites](#prerequisites)
- [Running Simulations](#running-simulations)

---

## 🎯 Project Overview

This project implements and evaluates **two approximate multiplier designs** with configurable approximation levels for improved hardware efficiency.

### Design Variants

| Design | Location | Description | Levels |
|--------|----------|-------------|--------|
| **approx_t** | `RTL/` | Base approximate multiplier | 0-5 |
| **approx_t_hetero** | `RTL_proposed/` | Heterogeneous optimized multiplier | 0-2 |

### Key Capabilities
- **Bit-widths**: 8-bit and 24-bit operands
- **Data types**: Integer, Fixed-point, Floating-point
- **Output**: CSV results + VCD waveforms for analysis
- **Automation**: Python-based simulation orchestrator

---

## 📁 Directory Structure

```
HETAM-ABS/
│
├── README.md                           # This file
├── run_approx_sim.py                   # Main simulation orchestrator (Python)
│
├── RTL/                                # Base multiplier design
│   ├── approx_t.v                      # Primary multiplier
│   ├── bit_mask_sel.v                  # Masking logic
│   ├── fixed_point_mul.v               # Fixed-point multiplier
│   ├── floating_point_mul.v            # Floating-point multiplier
│   ├── signed_int_mul.v                # Signed integer multiplier
│   ├── unsigned_int_mul.v              # Unsigned integer multiplier
│   ├── leading_one_detector.v          # Priority encoder
│   └── README                          # RTL documentation
│
├── RTL_proposed/                       # Proposed heterogeneous design
│   ├── approx_t_hetero.v               # Optimized multiplier
│   ├── bit_mask_sel.v                  # Masking logic
│   └── [Other supporting modules]
│
├── Test_Bench/                         # Base design testbenches
│   ├── approx_t/
│   │   ├── tb_approx_t.v               # Main testbench
│   │   ├── Fixed_point/                # Fixed-point tests
│   │   ├── Floating_point/             # Floating-point tests
│   │   ├── Signed_int/                 # Signed integer tests
│   │   └── Unsigned_int/               # Unsigned integer tests
│   └── [Other test types]
│
├── Test_Bench_proposed/                # Proposed design testbenches
│   └── approx_t_hetero/
│       └── [Similar structure as above]
│
├── FPGA_resources/                     # FPGA synthesis constraints
│   ├── constraint_approx_t_base.xdc
│   └── contraint_approx_t_hetero.xdc
│
└── [Auto-generated on first run]
    ├── Simulation_Results/             # CSV output files
    ├── vcd/                            # VCD waveform files
    └── Simulation_log/                 # Execution logs

```

---

## ✅ Prerequisites

### Install iverilog
```bash
sudo apt update
sudo apt install -y iverilog
iverilog -v              # Verify installation
```

### Install gtkwave
```bash
sudo apt install -y gtkwave
gtkwave --version        # Verify installation
```

### Verify Python
```bash
python3 --version        # Must be 3.6+ (standard library only)
```

---

## 🚀 Running Simulations

### Quick Start - Run Everything

```bash
python3 run_approx_sim.py
```

This will:
- Compile both designs (approx_t and approx_t_hetero)
- Generate 18 simulation configurations (2 widths × 9 levels)
- Create CSV results and VCD waveforms
- Runtime: ~90-120 seconds

### Run Specific Design

**Base design only:**
```bash
python3 run_approx_sim.py --designs base
```

**Proposed design only:**
```bash
python3 run_approx_sim.py --designs proposed
```

### Run Specific Width

**8-bit width only:**
```bash
python3 run_approx_sim.py --widths 8
```

**24-bit width only:**
```bash
python3 run_approx_sim.py --widths 24
```

### Run Specific Approximation Levels

**Levels 0-2 only (exact plus two approximation levels):**
```bash
python3 run_approx_sim.py --levels 0 1 2
```

**Level 5 only (maximum approximation):**
```bash
python3 run_approx_sim.py --levels 5
```

### Combine Options

**Proposed design, 8-bit width, specific levels:**
```bash
python3 run_approx_sim.py --designs proposed --widths 8 --levels 0 1 2
```

**Base design, 24-bit width, levels 0-5:**
```bash
python3 run_approx_sim.py --designs base --widths 24 --levels 0 1 2 3 4 5
```

### View Help

```bash
python3 run_approx_sim.py --help
```

---

## 📊 Output Files Generated

### CSV Results
Location: `Simulation_Results/<design>/results_w<WIDTH>_level<LEVEL>.csv`

Contains test vectors and error analysis.

### VCD Waveforms
Location: `vcd/<design>/<design>_w<WIDTH>_level<LEVEL>.vcd`

Complete signal traces for analysis. View with:
```bash
gtkwave vcd/approx_t/approx_t_w8_level0.vcd
```

### Simulation Logs
Location: `Simulation_log/` and `Simulation_log_proposed/`

Console output and compilation messages.

---

## 🔍 Troubleshooting

**Issue**: "Compile failed for approx_t"

**Solution**: Verify RTL files exist
```bash
ls -la RTL/*.v RTL_proposed/*.v
```

**Issue**: "VCD not found" after simulation

**Solution**: Check testbench paths are correct (relative paths from Test_Bench directory)

**Issue**: Python script not executable

**Solution**:
```bash
chmod +x run_approx_sim.py
python3 run_approx_sim.py
```

---


