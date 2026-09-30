# 16-bit RISC Processor

## Project Overview

This project implements a custom 16-bit RISC processor in synthesizable Verilog/SystemVerilog, with both FPGA and ASIC-oriented implementation flows.

The processor uses a Harvard architecture with separate instruction and data memories and a multi-cycle datapath controlled by a finite-state machine. The design covers processor microarchitecture, RTL development, functional verification, FPGA implementation, synthesis, and static timing analysis.

## Key Features

- 16-bit processor datapath
- Harvard architecture with separate instruction and data memories
- 8 × 16-bit register file
- 8-operation Arithmetic Logic Unit (ALU)
- Multi-cycle FSM-based control unit
- Custom 13-instruction ISA
- Synthesizable RTL design
- Self-checking SystemVerilog verification
- Basys 3 FPGA implementation
- SKY130 ASIC front-end implementation

## Instruction Set Architecture

The processor supports 13 instructions:

- `LD` – Load
- `ST` – Store
- `ADD` – Addition
- `SUB` – Subtraction
- `INV` – Bitwise inversion
- `LSL` – Logical shift left
- `LSR` – Logical shift right
- `AND` – Bitwise AND
- `OR` – Bitwise OR
- `SLT` – Set less than
- `BEQ` – Branch if equal
- `BNE` – Branch if not equal
- `JMP` – Jump

The ISA covers memory access, arithmetic, logical operations, shifting, comparison, branching, and control flow.

## Processor Architecture

The main architectural blocks include:

- Program Counter
- Instruction Memory
- Register File
- Arithmetic Logic Unit
- Data Memory
- Sign Extension Logic
- Instruction Decoder
- Multi-cycle Control FSM
- Write-back Multiplexer
- Branch and Jump Logic

The control FSM sequences instruction fetch, decode, execution, memory access, and write-back operations across multiple clock cycles.

## Verification

The processor was verified using a self-checking SystemVerilog testbench covering the supported instruction classes.

The verification environment checks expected processor behaviour across:

- Arithmetic and logical instructions
- Shift operations
- Register write-back
- Load and store operations
- Branch instructions
- Jump behaviour
- Program counter sequencing
- Data memory operations

Assertions and automated checks were used to identify errors in control sequencing, datapath operation, memory access, and instruction execution.

## Implementation Flows

### FPGA Implementation

The processor was implemented on a Digilent Basys 3 board using the Xilinx Artix-7 FPGA.

Key implementation results:

- Target clock: 100 MHz
- Post-route WNS: +0.137 ns
- LUTs: 395
- Flip-Flops: 163
- Block RAM: 2 RAMB18
- Estimated on-chip power: 73 mW

This stage provided hardware-level validation of the processor and allowed timing, resource utilisation, and power characteristics to be evaluated after FPGA implementation.

### ASIC Implementation

The processor architecture was also adapted for an ASIC-oriented front-end flow using the SKY130 standard-cell platform.

The ASIC work includes:

- RTL functional verification
- Timing-oriented RTL optimisation
- Yosys synthesis
- SDC timing constraints
- OpenSTA setup and hold analysis
- Gate-level netlist generation

The ASIC version was used to investigate timing-critical datapaths and explore architectural changes required when targeting a standard-cell implementation rather than an FPGA.

## Technologies and Tools

- Verilog
- SystemVerilog
- Xilinx Vivado
- Digilent Basys 3
- Xilinx Artix-7
- SKY130 standard-cell platform
- Yosys
- OpenSTA
- Icarus Verilog
- SDC timing constraints
- RTL simulation
- FPGA synthesis and implementation
- Static Timing Analysis (STA)

## Project Structure

```text
16bit-risc-processor/
├── rtl/          # Processor RTL
├── tb/           # SystemVerilog verification
├── programs/     # Processor test programs
├── fpga/         # Basys 3 implementation
└── asic/         # SKY130 ASIC-oriented implementation
