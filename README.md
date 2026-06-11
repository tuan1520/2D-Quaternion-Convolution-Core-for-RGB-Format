# 2D Quaternion Convolution Core for RGB Format

SystemVerilog RTL design of a 3x3 2D pure quaternion convolution core for RGB image processing.

## Overview

This project implements a hardware core for performing 3x3 2D pure quaternion convolution on RGB image streams. Each RGB pixel is represented as a pure quaternion, and the convolution result is computed through four output lanes corresponding to the scalar and imaginary quaternion components.

The design focuses on a streaming RTL architecture suitable for image-processing hardware, including line buffering, 3x3 window generation, signed arithmetic, multi-lane accumulation, control logic, FPGA validation, and ASIC synthesis evaluation.

## Main Features

- 3x3 pure quaternion convolution for RGB input data
- Streaming image-processing datapath
- Two-line buffer and 3x3 window generator
- Signed 9-bit kernel and pixel data handling
- Booth radix-4 and Wallace-tree based multiplier design
- Four-lane quaternion output accumulation
- FSM-based control flow for kernel loading, image processing, flushing, and completion
- Directed SystemVerilog testbenches for major RTL blocks
- FPGA demonstration flow on DE10 board
- ASIC synthesis evaluation using Cadence Genus

## Project Structure

```text
├── 00_src/      # RTL source files
├── 01_tb/       # SystemVerilog testbenches
├── 02_doc/      # Project report and design figures
├── 03_sim/      # Simulation files and related setup
├── 04_syn/      # ASIC synthesis environment
│   ├── constraints/
│   ├── filelist/
│   ├── libs/
│   ├── log/
│   ├── netlist/
│   ├── reports/
│   ├── scripts/
│   └── work/
└── 05_fpga/     # FPGA implementation and demo files
    ├── 00_quartus/
    └── 01_results/
```
