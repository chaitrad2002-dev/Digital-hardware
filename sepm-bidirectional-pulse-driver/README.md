# S-EPM Bidirectional Driver & FPGA Pulse-Control System

## Overview

This project combines the power-electronics hardware and digital control required to switch a Switchable-polarity Electro-Permanent Magnet (S-EPM) using short bidirectional current pulses.

The work progressed from coil characterisation, LTspice simulation and an L6203 H-bridge prototype to a four-channel FPGA pulse controller on the Digilent Basys 3. The hardware prototype demonstrates the high-current switching stage, while the FPGA implementation focuses on deterministic multi-channel pulse timing and safety logic.

The FPGA drives only the low-voltage control inputs of an external H-bridge. It does not drive the S-EPM coil directly.

## System Concept

```text
User / Control Command
          |
          v
   FPGA Pulse Controller
   - direction
   - pulse timing
   - dead-time
   - safety interlocks
          |
          v
   H-Bridge Power Driver
          |
          v
       S-EPM Coil
```

Reversing the H-bridge current direction changes the magnetic state of the S-EPM. Because the magnet is switched using short pulses, continuous coil current is not required.

## Hardware Development

The hardware stage was developed around a full H-bridge so that the coil current can be applied in either direction.

Experimental work used an S-EPM prototype with a measured coil resistance of approximately **5.9 ohms**. Reliable switching was observed from approximately **18-20 V**, with measured coil current of about:

- **3.0 A at 20 V**
- **5 A at 30 V**

A typical switching pulse used during development was approximately **1 ms**.

The compact prototype used the **ST L6203 full-bridge driver**, with bulk energy storage and transient protection around the inductive load. Early control experiments used an Arduino Uno to validate forward and reverse switching before moving the timing and safety functions to FPGA logic.

## LTspice Reference Model

A reference transient model was used to study the S-EPM current rise:

- Supply voltage: **30 V**
- Coil resistance: **4 ohms**
- Coil inductance: **192.3 uH**
- Electrical time constant: **48.1 us**
- Steady-state current: **7.5 A**

A 1 ms pulse is much longer than the electrical time constant in this reference case, so the simulated coil current approaches its steady-state value before the end of the pulse.

The 4-ohm LTspice model is a reference design case and is separate from the approximately 5.9-ohm coil used in the hardware measurements.

## FPGA Control - Stage 1

The FPGA implementation targets the **Digilent Basys 3 / Xilinx Artix-7 XC7A35T** at **100 MHz**.

Stage 1 implements four independent S-EPM pulse engines with:

- Four independently enabled channels
- Forward and reverse polarity control
- **1 ms pulse width = 100,000 clock cycles**
- **1 us pre/post dead-time = 100 clock cycles**
- Global ARM control
- Active-high ESTOP input
- Active-high FAULT input
- Busy and done status per channel
- Immediate output gating when ARM is removed or ESTOP/FAULT is asserted

The four channels can operate independently or simultaneously.

## FPGA Architecture

The control logic is separated into reusable modules:

- `sepm_pulse_seq.sv` - per-pulse state machine and safety gating
- `sepm_channel.sv` - channel enable and pulse-engine wrapper
- `sepm_4ch_core.sv` - four-channel generate structure
- `basys3_sepm_top.sv` - Basys 3 switches, buttons, LEDs and Pmod mapping

The pulse sequencer uses four states:

```text
IDLE -> DEAD_PRE -> PULSE -> DEAD_POST -> IDLE
```

During the `PULSE` state, only one bridge input can be asserted for a channel. Forward polarity drives `IN1`; reverse polarity drives `IN2`.

## Basys 3 Controls

- `BTNC` - reset
- `BTNU` - trigger channel 0
- `BTND` - trigger channel 1
- `BTNL` - trigger channel 2
- `BTNR` - trigger channel 3
- `SW15` - global ARM
- `SW14` - FAULT
- `SW13` - ESTOP
- `SW3:0` - channel enables
- `SW7:4` - channel polarities

Eight control outputs are mapped to Pmod JA as two H-bridge logic signals per channel.

## Verification

A self-checking SystemVerilog testbench verifies:

- Forward operation on all four channels
- Reverse operation on all four channels
- Simultaneous mixed-polarity pulses
- Exact pulse-cycle count
- Re-trigger rejection while a channel is busy
- ESTOP pulse abort
- FAULT pulse abort
- Disabled-channel trigger rejection
- Assertion that `IN1` and `IN2` are never high together on the same channel

The expected successful simulation message is:

```text
SEPM 4CH SELF-CHECK: PASS
```

## Repository Structure

```text
sepm-bidirectional-pulse-driver/
├── README.md
├── hardware/
│   └── README.md
└── fpga/
    ├── README.md
    ├── rtl/
    ├── tb/
    ├── constraints/
    └── vivado/
```

## Tools and Technologies

- SystemVerilog
- Xilinx Vivado
- Digilent Basys 3 / Artix-7
- LTspice
- KiCad
- Arduino Uno for early hardware prototyping
- ST L6203 full-bridge driver
- Oscilloscope and current-probe measurements

## Current Status

The repository contains the Stage 1 four-channel FPGA timing and safety core together with documentation of the earlier hardware-driver development. The FPGA design should first be validated at logic level before connection to a power stage.

Future work includes multi-channel power hardware, full FPGA-to-driver integration, and a command/CDC interface for higher-level control.
