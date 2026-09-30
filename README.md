# Digital Hardware Portfolio

A collection of my RTL, FPGA, ASIC, and digital design projects.

My work focuses on processor design, Verilog/SystemVerilog RTL, functional verification, FPGA implementation, timing analysis, and ASIC design flows.

---

## Projects

### 16-bit RISC Processor

Custom 16-bit processor with a Harvard architecture, multi-cycle FSM control, 8 × 16-bit register file, 8-operation ALU, and a 13-instruction ISA.

The design was verified using SystemVerilog and implemented through both FPGA and ASIC flows.

**Highlights**
- Basys 3 / Artix-7 FPGA implementation
- 100 MHz target clock
- +0.137 ns post-route WNS
- SKY130 ASIC implementation
- Synthesis and Static Timing Analysis
- Placement, CTS, routing and physical-design analysis

[View Project](./16bit-risc-processor)

---

### 8-bit Processor with VGA and PS/2

Processor-based digital system integrating CPU logic, memory, VGA display generation, PS/2 mouse-interface RTL, timers, and peripheral control.

**Highlights**
- 8-bit processor architecture
- Memory-mapped system
- VGA 640 × 480 display
- PS/2 mouse interface
- FSM-based peripheral control
- Basys 3 FPGA development

[View Project](./8bit-processor-vga-ps2)

---


