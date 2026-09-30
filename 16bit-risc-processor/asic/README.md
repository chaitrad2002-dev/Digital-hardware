# 16-bit RISC Processor — ASIC Implementation

## Overview

This section documents the ASIC implementation of the custom 16-bit RISC processor using the SKY130 standard-cell platform.

The processor RTL was adapted from the FPGA version and taken through an ASIC-oriented flow covering functional verification, synthesis, timing optimisation, static timing analysis, placement, clock-tree synthesis, routing, congestion analysis, critical-path inspection, and power-delivery analysis.

The purpose of this implementation was to explore how the same processor architecture behaves when moved from an FPGA target to a standard-cell ASIC flow.

## Design Flow

The ASIC implementation followed these main stages:

1. RTL design and functional verification
2. Timing-oriented RTL optimisation
3. Logic synthesis
4. SDC timing constraint definition
5. Static Timing Analysis (STA)
6. Standard-cell placement
7. Clock Tree Synthesis (CTS)
8. Routing
9. Congestion analysis
10. Critical timing-path analysis
11. IR-drop analysis

## ASIC RTL

The ASIC version uses a dedicated top-level wrapper and timing-oriented modifications to the processor core.

The main RTL blocks include:

- 16-bit processor core
- 8 × 16-bit register file
- Arithmetic Logic Unit
- FSM-based control logic
- ASIC-specific top-level interface

The processor architecture remains based on the same custom 13-instruction ISA used in the FPGA implementation.

## Functional Verification

A self-checking SystemVerilog testbench was used to verify the ASIC-oriented RTL before synthesis.

Verification covers processor behaviour including:

- Arithmetic instructions
- Logical operations
- Shift operations
- Register write-back
- Load and store behaviour
- Branch instructions
- Jump operations
- Program-counter sequencing

This step ensures that timing and implementation changes do not alter the intended processor functionality.

## Timing Constraints

The design was constrained for a 100 MHz target clock.

Key timing assumptions include:

- Clock period: 10 ns
- Clock uncertainty: 0.2 ns
- Input delay: 1.0 ns
- Output delay: 1.0 ns

These constraints are used during synthesis and static timing analysis.

## Timing Optimisation

Timing analysis was used to identify long combinational paths in the processor datapath.

The processor control sequence was modified to reduce the length of timing-critical paths by introducing an additional register-file read stage and separating some operations across clock cycles.

This demonstrates an important ASIC design trade-off: increasing latency by one control stage can reduce combinational path delay and improve timing closure.

## Logic Synthesis

The RTL was synthesized against the SKY130 standard-cell library.

The synthesis flow converts the behavioural RTL into a gate-level implementation composed of standard cells while preserving the processor's functional behaviour.

Synthesis was also used to evaluate:

- Logic structure
- Register usage
- Timing-critical paths
- Cell-level implementation
- Gate-level netlist generation

## Static Timing Analysis

Static Timing Analysis was used to evaluate whether the implemented design satisfies the defined clock and I/O timing constraints.

Both setup and hold behaviour were analysed to identify paths that could limit the operating frequency or cause timing violations.

## Physical Design

The synthesized processor was taken through physical-design stages to examine the actual placement and interconnection of standard cells.

### Placement

Standard cells were positioned within the defined core area while considering connectivity and routing requirements.

![ASIC Placement](docs/images/placement.png)

### Clock Tree Synthesis

Clock Tree Synthesis was used to distribute the clock signal across sequential elements while controlling clock latency and skew.

![Clock Tree](docs/images/clock_tree_layout.png)

### Routing

After placement and clock-tree synthesis, signal nets were physically routed between standard cells.

![Routed ASIC Layout](docs/images/routed_layout.png)

### Congestion Analysis

Routing congestion was analysed across the processor core to identify regions with high routing demand.

![Congestion Analysis](docs/images/congestion_map.png)

### Critical Timing Path

Timing-critical paths were inspected after physical implementation to understand which logic and interconnect paths have the greatest effect on timing performance.

![Worst Timing Path](docs/images/worst_timing_path.png)

### IR-Drop Analysis

Power-delivery behaviour was analysed across the placed design to examine voltage-drop distribution within the core.

![IR Drop Analysis](docs/images/ir_drop.png)

## Additional Physical-Design Views

### Clock Distribution

![Clock Routes](docs/images/clock_routes.png)

### Cell Resizing

![Resized Cells](docs/images/resized_cells.png)

### Final Physical Layout

![Final ASIC Layout](docs/images/final_layout.png)

## Tools and Technologies

- SystemVerilog
- SKY130 standard-cell platform
- Yosys
- OpenSTA
- Icarus Verilog
- SDC timing constraints
- RTL simulation
- Logic synthesis
- Static Timing Analysis
- Placement
- Clock Tree Synthesis
- Routing
- Congestion analysis
- IR-drop analysis

## What This Implementation Demonstrates

This implementation demonstrates the progression of a processor design from synthesizable RTL to a standard-cell ASIC implementation.

It provided practical experience in:

- Adapting RTL for ASIC timing requirements
- Writing timing constraints
- Analysing setup and hold timing
- Investigating critical paths
- Understanding placement and routing
- Evaluating routing congestion
- Examining clock distribution
- Analysing power-delivery effects
- Comparing FPGA and ASIC implementation approaches
