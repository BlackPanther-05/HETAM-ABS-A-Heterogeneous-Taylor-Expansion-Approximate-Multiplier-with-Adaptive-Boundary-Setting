# Heterogeneous Approximate Multiplier Design

A comprehensive RTL and simulation framework for evaluating approximate multiplier designs across multiple data types and approximation levels.

**Status**: Production-ready | **Last Updated**: March 2026 | **Language**: Verilog + Python

---

## 📋 Table of Contents

- [Project Overview](#project-overview)
- [Key Features](#key-features)
- [Directory Structure](#directory-structure)
- [Getting Started](#getting-started)
- [Running Simulations](#running-simulations)
- [Design Details](#design-details)
- [Output Files](#output-files)
- [Data Types Supported](#data-types-supported)
- [Design Specifications](#design-specifications)
- [Troubleshooting](#troubleshooting)

---

## 🎯 Project Overview

This project implements and evaluates **two approximate multiplier designs** that trade off accuracy for improved hardware efficiency (reduced power, area, and delay). The framework enables rigorous comparative analysis across:

- **Multiple data types**: Fixed-point, Floating-point, Signed Integer, Unsigned Integer
- **Multiple approximation levels**: 0 (exact) through 5 (maximum approximation)
- **Multiple bit-widths**: 8-bit and 24-bit operands
- **Real-world applications**: BERT, HuBERT, LeNet-5

### Design Variants

| Design | RTL Location | Description | Levels | Status |
|--------|-------------|-------------|--------|--------|
| **approx_t** | `RTL/` | Base approximate multiplier with 6 approximation levels | 0-5 | ✅ Baseline |
| **approx_t_hetero** | `RTL_proposed/` | Heterogeneous approximate multiplier (optimized) | 0-2 | ✅ Proposed |

---

## ✨ Key Features

### Simulation Framework
- **Automated compilation** via iverilog with parameter override support
- **Comprehensive testing** across bit-widths and approximation levels
- **VCD waveform generation** for power analysis and debugging
- **CSV result logging** with error metrics and statistics
- **Parallel execution** support via ThreadPoolExecutor (future enhancement)
- **Flexible design selection** - run specific designs, widths, or levels

### Design Capabilities
- **Configurable precision** - approximate least significant bits (LSBs)
- **Dynamic masking** - runtime-adjustable approximation levels
- **Support for multiple operand widths** - 8, 16, 24, 32-bit (configurable)
- **Module hierarchy** - bit_mask_sel, leading_one_detector, type-specific multipliers

### Output Artifacts
- **Simulation Results** - CSV files with error analysis per configuration
- **VCD Waveforms** - Complete signal traces for all levels and widths
- **Log Files** - Timestamped execution logs
- **Synthesis Reports** - ASIC (Genus) and FPGA (Vivado) results

---

## 📁 Directory Structure

```
Heterogenus_Approx_t_multiplier/
│
├── README.md                           # This file
├── run_approx_sim.py                   # Main simulation orchestrator
│
├── RTL/                                # Base multiplier design
│   ├── approx_t.v                      # Primary multiplier (levels 0-5)
│   ├── bit_mask_sel.v                  # Masking logic for approximation
│   ├── fixed_point_mul.v               # Fixed-point implementation
│   ├── floating_point_mul.v            # Floating-point implementation
│   ├── signed_int_mul.v                # Signed integer implementation
│   ├── unsigned_int_mul.v              # Unsigned integer implementation
│   ├── leading_one_detector.v          # Priority encoder (FP support)
│   └── README                          # RTL documentation
│
├── RTL_proposed/                       # Proposed heterogeneous design
│   ├── approx_t_hetero.v               # Optimized multiplier (levels 0-2)
│   └── bit_mask_sel.v                  # Masking logic (shared structure)
│
├── Test_Bench/                         # Base design testbenches
│   └── approx_t/
│       ├── tb_approx_t.v               # Primary testbench
│       ├── Fixed_point/                # Fixed-point test vectors
│       ├── Floating_point/             # Floating-point test vectors
│       ├── Signed_int/                 # Signed integer test vectors
│       └── Unsigned_int/               # Unsigned integer test vectors
│
├── Test_Bench_proposed/                # Proposed design testbenches
│   └── approx_t_hetero/
│       ├── tb_approx_t_hetero.v        # Proposed testbench
│       └── [Similar subdirs as above]
│
├── Simulation_Results/                 # Output CSV files (auto-created)
│   ├── approx_t/                       # Base design results
│   ├── approx_t_hetero/                # Proposed design results
│   ├── Fixed_point/                    # Fixed-point simulation data
│   ├── Floating_point/                 # Floating-point simulation data
│   ├── base/                           # Base configurations
│   │   ├── Signed_int/
│   │   └── Unsigned_int/
│   └── proposed/                       # Proposed configurations
│       ├── Signed_int/
│       └── Unsigned_int/
│
├── vcd/                                # VCD waveform files (auto-created)
│   ├── approx_t/                       # Base design waveforms
│   │   ├── approx_t_w8_level0.vcd
│   │   ├── approx_t_w8_level*.vcd
│   │   ├── approx_t_w24_level*.vcd
│   │   └── ...
│   └── approx_t_hetero/                # Proposed design waveforms
│       ├── approx_t_hetero_w8_level*.vcd
│       ├── approx_t_hetero_w24_level*.vcd
│       └── ...
│
├── Simulation_log/                     # Execution logs (auto-created)
├── Simulation_log_proposed/            # Proposed design logs
│
├── FPGA_resources/                     # FPGA synthesis resources
│   ├── constraint_approx_t_base.xdc    # Vivado constraints (base)
│   └── contraint_approx_t_hetero.xdc   # Vivado constraints (proposed)
│
├── ASIC_Results/                       # ASIC synthesis results
│   └── Genus_Results/                  # Cadence Genus reports
│
├── Application_Model/                  # Integration with ML models
│   ├── BERT_sst2_L6/                   # BERT inference with approx multipliers
│   ├── HuBert_model/                   # HuBert inference
│   └── Lenet-5_MNIST/                  # LeNet-5 inference
│
└── [Individual simulation scripts]      # Deprecated (use run_approx_sim.py)
    ├── fixed_point_testbench_Simulation.py
    ├── float_point_testbench_simulation.py
    ├── signed_int_testbench_simulation.py
    └── unsigned_int_testbench_simulation.py
```

---

## 🚀 Getting Started

### Prerequisites

```bash
# Required tools
sudo apt install iverilog              # Icarus Verilog compiler & simulator

# Python 3.8+ (standard library only)
python3 --version
```

### Installation

1. **Clone/Navigate to project directory**
   ```bash
   cd Heterogenus_Approx_t_multiplier
   ```

2. **Verify source files**
   ```bash
   python3 run_approx_sim.py --help
   ```

3. **First run** (all designs, all levels)
   ```bash
   python3 run_approx_sim.py
   ```

---

## 🏃 Running Simulations

### Quick Start - Run Everything

```bash
python3 run_approx_sim.py
```

**What it does:**
- Compiles both `approx_t` and `approx_t_hetero` designs
- Generates 18 simulation configurations (2 widths × (6+3 levels))
- Creates CSV results and VCD waveforms
- Total runtime: ~90-120 seconds

### Advanced Usage

#### Run only base design
```bash
python3 run_approx_sim.py --designs base
```

#### Run only 8-bit width
```bash
python3 run_approx_sim.py --widths 8
```

#### Run specific levels
```bash
python3 run_approx_sim.py --levels 0 2 4
```

#### Combine options
```bash
python3 run_approx_sim.py --designs proposed --widths 24 --levels 0 1 2
```

### Script Output

```
======================================================================
  Approximate Multiplier Simulation Runner
======================================================================
  Project root : /path/to/project
  Designs      : approx_t, approx_t_hetero
  Widths       : [8, 24]
  CSV output   : Simulation_Results/<design>/
  VCD output   : vcd/<design>/
  Total pairs  : 18
======================================================================

[OK] iverilog  : /usr/bin/iverilog
[OK] vvp       : /usr/bin/vvp

Creating output directories...
  [DIR] Simulation_Results/approx_t/
  [DIR] vcd/approx_t/
  ...

[OK] All source files present.

======================================================================
  DESIGN: approx_t
======================================================================

  approx_t | WIDTH = 8
  
  Compiling approx_t for WIDTH=8...
  [OK]   Binary -> Test_Bench/approx_t/sim_w8

    approx_t WIDTH=8  LEVEL=0
  [OK]   Simulation done
  [OK]   VCD verified: vcd/approx_t/approx_t_w8_level0.vcd (24,635,411 bytes)
  [OK]   CSV : Simulation_Results/approx_t/results_w8_level0.csv (1,097,785 bytes)
  [OK]   VCD : vcd/approx_t/approx_t_w8_level0.vcd (24,635,411 bytes)
  
  ...

======================================================================
  FINAL SUMMARY
======================================================================

  approx_t:
    WIDTH=8:
      Level 0: OK (1.1s)
      Level 1: OK (1.0s)
      Level 2: OK (1.0s)
      Level 3: OK (1.1s)
      Level 4: OK (1.1s)
      Level 5: OK (1.1s)
    WIDTH=24:
      Level 0: OK (13.0s)
      Level 1: OK (13.2s)
      ...

  Total time : 94.4s

  Output locations:
    approx_t:
      CSV : Simulation_Results/approx_t/results_wW_levelL.csv
      VCD : vcd/approx_t/approx_t_wW_levelL.vcd
```

---

## 🔧 Design Details

### Module Hierarchy

#### **approx_t** (Base Design)

```verilog
module approx_t #(parameter WIDTH = 8)
  input  [WIDTH-1:0] x, y
  input  [5:0]       Conf_Bit_Mask     // 6 levels (0-5)
  output [2*WIDTH-1:0] f
  
  // Internally:
  // - Applies mask to LSBs based on approximation level
  // - Performs multiplication on masked operands
  // - Supports 8-bit and 24-bit widths
```

**Approximation Levels:**
| Level | Description | LSBs Masked |
|-------|-------------|------------|
| 0 | Exact multiplication | 0 |
| 1 | 1 LSB approximation | 1 |
| 2 | 2 LSB approximation | 2 |
| 3 | 3 LSB approximation | 3 |
| 4 | 4 LSB approximation | 4 |
| 5 | 5 LSB approximation | 5 |

#### **approx_t_hetero** (Proposed Heterogeneous Design)

```verilog
module approx_t_hetero #(parameter WIDTH = 8)
  // Similar interface as approx_t, but with optimized architecture
  // Only supports levels 0-2 (more efficient for practical use)
```

**Key Optimization**: Heterogeneous approximation strategy provides better accuracy-efficiency tradeoff at levels 0-2.

### bit_mask_sel Module

```verilog
// Generates approximation mask based on level
// Masks LSBs of operands before multiplication
module bit_mask_sel
  input [LEVEL -1:0] approximation_level
  output [WIDTH-1:0] mask
```

---

## 📊 Output Files

### Simulation Results (CSV Format)

**File**: `Simulation_Results/<design>/results_w<WIDTH>_level<LEVEL>.csv`

**Contents**: Test vector results with error analysis
```
Operand_A, Operand_B, Exact_Result, Approx_Result, Absolute_Error, Relative_Error, Test_Count
...
```

**Size**: ~1-20 MB per configuration
- WIDTH=8: ~1-2 MB (16K test vectors)
- WIDTH=24: ~15-20 MB (100K+ random test vectors)

### VCD Waveform Files

**File**: `vcd/<design>/<design>_w<WIDTH>_level<LEVEL>.vcd`

**Contents**: Complete signal trace dump
- All module inputs/outputs
- Intermediate computation signals
- Test configuration parameters

**Size**: ~20-500 MB per configuration
- WIDTH=8: ~20-30 MB
- WIDTH=24: ~400-500 MB

**Viewing VCD files** (with standard EDA tools):
```bash
# GTKWave (recommended)
gtkwave vcd/approx_t/approx_t_w8_level0.vcd

# Other tools: VCS, QuestaSim, Vivado, etc.
```

### Log Files

**Location**: `Simulation_log/` and `Simulation_log_proposed/`

**Contents**: Compilation and simulation console output
- iverilog warnings/errors
- Testbench messages
- Simulation timing

---

## 📈 Data Types Supported

### Via Main Simulation Runner (`run_approx_sim.py`)

- ✅ **Integer (8, 24-bit)**: approx_t and approx_t_hetero cores
- 📝 **Fixed-Point**: Dedicated testbenches (legacy)
- 📝 **Floating-Point**: Dedicated testbenches (legacy)
- 📝 **Signed/Unsigned**: Type-specific testbenches (legacy)

### Legacy Individual Simulation Scripts

Each data type has dedicated test scripts (auto-generated from templates):

```bash
# Fixed-point testing
python3 fixed_point_testbench_Simulation.py          # Base
python3 fixed_point_proposed_testbench_Simulation.py # Proposed

# Floating-point testing
python3 float_point_testbench_simulation.py          # Base
python3 float_point_proposed_testbench_simulation.py # Proposed

# Integer testing
python3 signed_int_testbench_simulation.py           # Base, signed
python3 signed_int_proposed_testbench_simulation.py  # Proposed, signed
python3 unsigned_int_testbench_simulation.py         # Base, unsigned
python3 unsigned_int_proposed_testbench_simulation.py # Proposed, unsigned
```

---

## 📝 Design Specifications

### Multiplier Specifications

| Parameter | approx_t | approx_t_hetero |
|-----------|----------|-----------------|
| **Max Operand Bits** | 24 | 24 |
| **Result Bits** | 2 × WIDTH | 2 × WIDTH |
| **Approximation Levels** | 0-5 | 0-2 |
| **LSB Masking Strategy** | Direct | Heterogeneous |
| **Synthesis Target** | ASIC (Genus) | ASIC/FPGA |

### Test Coverage

| Design | WIDTH | Levels | Test Vectors |
|--------|-------|--------|--------------|
| approx_t | 8 | 0-5 | 16,384 (full sweep) |
| approx_t | 24 | 0-5 | 100,000 (random) |
| approx_t_hetero | 8 | 0-2 | 16,384 (full sweep) |
| approx_t_hetero | 24 | 0-2 | 100,000 (random) |

**Total: 1.2M+ test vectors per full run**

---

## 🔍 Troubleshooting

### Issue: "Compile failed for approx_t WIDTH=8"

**Cause**: Verilog source files missing or syntax errors

**Solution**:
```bash
# Verify all RTL files exist
ls -la RTL/*.v RTL_proposed/*.v Test_Bench*/*/tb*.v

# Check for syntax errors with iverilog
iverilog -g2012 RTL/approx_t.v RTL/bit_mask_sel.v
```

### Issue: "VCD not found" after simulation

**Cause**: Testbench `$dumpfile` paths incorrect or vvp run from wrong directory

**Solution**:
- Paths in testbench must be relative to Test_Bench directory (where vvp executes from)
- Check `tb_approx_t.v` lines 259-273 for correct `../../vcd/` paths

### Issue: "CSV is missing or empty"

**Cause**: Testbench doesn't write to CSV file

**Solution**:
- VCD generation is independent of CSV
- Check testbench `$fopen` directives
- Verify `Simulation_Results/<design>/` directory is writable

### Issue: VCD file is very large (>1GB)

**Expected behavior** - VCD files capture all signals for 100K+ test vectors
- WIDTH=24 configs generate 400-500 MB VCD files (normal)
- Use sparse dumping if disk space is limited (modify testbench)

### Issue: Python script not executable

**Solution**:
```bash
chmod +x run_approx_sim.py
python3 run_approx_sim.py        # Or use explicitly
```

---

## 📋 Quick Reference

### Common Commands

```bash
# Run everything
python3 run_approx_sim.py

# Run only base design, all levels
python3 run_approx_sim.py --designs base

# Run only proposed, 8-bit width, levels 0-2
python3 run_approx_sim.py --designs proposed --widths 8 --levels 0 1 2

# View help
python3 run_approx_sim.py --help

# View a VCD file
gtkwave vcd/approx_t/approx_t_w8_level0.vcd

# Check simulation results
head Simulation_Results/approx_t/results_w8_level0.csv
tail Simulation_Results/approx_t/results_w8_level0.csv

# List all generated VCD files
ls -lh vcd/*/
```

### Environment Variables

```bash
# Python version check
python3 --version              # Must be 3.6+

# Tool availability
which iverilog                 # /usr/bin/iverilog
which vvp                      # /usr/bin/vvp
```

---

## 📄 File Manifest

### RTL Source Files

| File | Lines | Purpose |
|------|-------|---------|
| `RTL/approx_t.v` | ~400 | Primary approximate multiplier (levels 0-5) |
| `RTL/bit_mask_sel.v` | ~150 | LSB masking logic selector |
| `RTL/signed_int_mul.v` | ~100 | 2's complement signed multiplier |
| `RTL/unsigned_int_mul.v` | ~100 | Unsigned multiplier |
| `RTL/fixed_point_mul.v` | ~120 | Fixed-point arithmetic multiplier |
| `RTL/floating_point_mul.v` | ~200 | IEEE 754 floating-point multiplier |
| `RTL/leading_one_detector.v` | ~80 | Priority encoder for FP normalization |

### Testbench Files

| File | Purpose |
|------|---------|
| `Test_Bench/approx_t/tb_approx_t.v` | Base design testbench (1000+ lines) |
| `Test_Bench_proposed/approx_t_hetero/tb_approx_t_hetero.v` | Proposed design testbench |

### Python Scripts

| Script | Purpose |
|--------|---------|
| `run_approx_sim.py` | **Main** - Orchestrates all simulations |
| `*_testbench_Simulation.py` | Standalone type-specific simulators (legacy) |

---

## 🎓 Usage Examples

### Example 1: Compare accuracy of both designs at level 2

```bash
# Run level 2 only
python3 run_approx_sim.py --levels 2

# Check results
paste \
  <(tail -5 Simulation_Results/approx_t/results_w8_level2.csv) \
  <(tail -5 Simulation_Results/approx_t_hetero/results_w8_level2.csv)
```

### Example 2: Generate waveforms for debugging

```bash
# Run only level 0 (exact) for detailed inspection
python3 run_approx_sim.py --levels 0

# Open in GTKWave
gtkwave vcd/approx_t/approx_t_w24_level0.vcd

# Look for: exact_result vs approx_result signals
```

### Example 3: Benchmark power consumption

```bash
# Generate all VCD files needed for power analysis
python3 run_approx_sim.py

# Use Cadence Genus (if available):
genus -no_gui -exec "read_saif -input vcd/approx_t/approx_t_w8_level5.saif ..."
```

---

## 📞 Support & Contact

For issues, improvements, or questions:

1. **Check existing logs**: `Simulation_log/` and `Simulation_log_proposed/`
2. **Verify prerequisites**: All dependencies installed?
3. **Test a simple case**: `python3 run_approx_sim.py --widths 8 --levels 0`
4. **Review RTL README**: `RTL/README` for design-specific details

---

## 📜 License & Attribution

This project is part of the Samsung Chip Design research initiative at [Institution].

**Citation**:
```
Heterogeneous Approximate Multiplier Design for Energy-Efficient Computing
[Author Names], [Year], [Conference/Journal]
```

---

## ✅ Verification Checklist

Before using this framework:

- [ ] `iverilog --version` shows v12.0 or later
- [ ] `python3 --version` shows v3.6 or later
- [ ] All RTL files present: `ls RTL/*.v` shows 8 files
- [ ] Both test benches exist: `ls Test_Bench*/*/tb*.v` shows 2 files
- [ ] `run_approx_sim.py` is executable or run via `python3`
- [ ] Disk space available: ~10GB for full run outputs

---

## 📈 Project Statistics

- **Total RTL Lines**: ~1,500 lines of Verilog
- **Total Test Vectors**: 1.2M+ per full simulation run
- **Total Generated Outputs**: ~3GB (VCD + CSV)
- **Simulation Time**: ~90-120 seconds per full run
- **Supported Configurations**: 18 (2 designs × 2 widths × (6+3) levels)

---

**Last Updated**: March 11, 2026 | **Version**: 1.0.0
