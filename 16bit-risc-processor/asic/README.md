# ASIC Implementation

## Overview

This folder documents the ASIC-oriented implementation of the 16-bit RISC processor.

The same verified RTL used for the FPGA implementation is reused for the ASIC flow, allowing the design to be evaluated through synthesis, timing analysis, area analysis, and physical-design stages where completed.

## ASIC Design Flow

The project follows an ASIC implementation flow including:

1. RTL design and functional verification
2. Logic synthesis
3. Gate-level netlist generation
4. Static Timing Analysis (STA)
5. Area analysis
6. Physical design and layout, where completed
7. Extraction and post-layout analysis, where available

## Planned Folder Structure

- `scripts/` – synthesis and implementation scripts
- `reports/` – timing, area, power, and synthesis reports
- `netlist/` – synthesized gate-level netlists
- `layout/` – DEF, GDSII, SPEF, or other physical-design outputs where generated

## Common RTL

The synthesizable processor RTL is maintained in the main `rtl/` directory so both FPGA and ASIC implementations use the same design source.
