# 16-bit RISC Processor

## Project Overview

This project implements a custom 16-bit RISC processor in synthesizable Verilog and targets the Digilent Basys 3 FPGA.

The processor uses a Harvard architecture with separate instruction and data memories and a multi-cycle datapath controlled by a finite-state machine.

The design was developed to strengthen practical understanding of processor architecture, RTL design, control-path implementation, memory interfacing, verification, synthesis, and FPGA timing analysis.

## Key Features

- **16-bit datapath**
- **Harvard architecture** with separate instruction and data memories
- **8 × 16-bit register file**
- **8-operation ALU**
- **Multi-cycle control FSM**
- **Custom 13-instruction ISA**
- **Synthesizable Verilog RTL**
- **Basys 3 FPGA implementation**
- **Self-checking SystemVerilog verification**

## Instruction Set Architecture

The processor supports 13 instructions:

- LD
- ST
- ADD
- SUB
- INV
- LSL
- LSR
- AND
- OR
- SLT
- BEQ
- BNE
- JMP

The ISA covers memory access, arithmetic, logic, shifting, comparison, branching, and control-flow operations.

## Processor Architecture

The main architectural blocks include:

- Program Counter
- Instruction Memory
- Register File
- Arithmetic Logic Unit
- Data Memory
- Sign Extension Logic
- Instruction Decoder
- Control FSM
- Write-back Multiplexer
- Branch and Jump Logic

## FPGA Implementation

The processor was implemented on a Digilent Basys 3 development board using a Xilinx Artix-7 FPGA.

Reported post-route implementation results include:

- **Clock Frequency:** 100 MHz
- **Worst Negative Slack:** +0.137 ns
- **LUTs:** 395
- **Flip-Flops:** 163
- **Block RAM:** 2 RAMB18
- **Estimated On-Chip Power:** 73 mW

## Verification

Verification includes a self-checking SystemVerilog testbench covering the supported instruction classes.

The verification environment checks processor behaviour against expected results and helps identify errors in instruction decoding, datapath control, memory access, and branch handling.

## Technologies and Tools

- Verilog
- SystemVerilog
- Xilinx Vivado
- Basys 3
- Artix-7 FPGA
- RTL simulation
- Synthesis
- Implementation
- Static timing analysis

## Key Learning Outcomes

- Designing a processor datapath from RTL
- Developing multi-cycle FSM control
- Implementing a custom instruction set
- Understanding register-file and memory interfaces
- Verifying processor behaviour using self-checking testbenches
- FPGA synthesis, implementation, and timing analysis

## Repository Contents

This folder contains the processor RTL, verification files, FPGA constraints, memory initialization files, and implementation documentation.
