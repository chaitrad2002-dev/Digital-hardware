# 4-Channel S-EPM FPGA Pulse Controller - Stage 1

This folder contains the FPGA portion of the S-EPM project. It generates logic-level H-bridge control signals only; the S-EPM coil must be driven through a suitable external power stage.

Target board: Digilent Basys 3 / Artix-7 XC7A35T-1CPG236C
Clock: 100 MHz

This stage implements four independent S-EPM pulse engines. UART/CDC command transport is intentionally deferred to Stage 2 so the four-channel timing/safety core can be validated first.

## Fixed hardware-test settings
- Pulse width: 1 ms = 100,000 cycles at 100 MHz
- Pre/post dead-time: 1 us = 100 cycles
- Four independent channels
- Forward/reverse polarity per channel
- Global ARM, ESTOP and FAULT
- Per-channel enable and busy/done status

## Basys 3 controls
- BTNC: synchronous reset
- BTNU: trigger CH0
- BTND: trigger CH1
- BTNL: trigger CH2
- BTNR: trigger CH3
- SW15: global ARM
- SW14: FAULT (1 = active)
- SW13: ESTOP (1 = active)
- SW3:0: CH3:0 enable
- SW7:4: CH3:0 polarity (1 = forward, 0 = reverse)

## LEDs
- LED3:0: busy CH3:0
- LED7:4: one-cycle done indication CH3:0
- LED11:8: IN1 CH3:0
- LED15:12: IN2 CH3:0

## Pmod JA mapping
The 8 bridge-control logic outputs are packed as:
`sepm_out = {CH3_IN2, CH3_IN1, CH2_IN2, CH2_IN1, CH1_IN2, CH1_IN1, CH0_IN2, CH0_IN1}`

Do not connect the Pmod pins directly to a high-voltage/high-current H-bridge unless the H-bridge inputs are electrically compatible with 3.3-V FPGA logic and the required isolation/protection is present.

## Run behavioral simulation in Vivado Tcl
From this project root:

```tcl
source vivado/run_sim.tcl
```

Expected console message:
`SEPM 4CH SELF-CHECK: PASS`

The self-check covers:
- forward/reverse on all four channels
- simultaneous mixed-polarity pulses
- exact pulse-cycle count
- busy retrigger rejection
- ESTOP abort
- FAULT abort
- disabled-channel trigger rejection
- assertion that IN1 and IN2 are never high together on a channel

## Build FPGA bitstream
From Vivado Tcl console, with current directory set to this project root:

```tcl
source vivado/create_and_build.tcl
```

Generated reports:
- reports/post_impl_utilization.rpt
- reports/post_impl_timing_summary.rpt
- reports/power.rpt
- reports/route_status.rpt
- reports/clock_utilization.rpt
- reports/sepm4_basys3.bit

## Initial board test
1. Program `reports/sepm4_basys3.bit`.
2. Keep SW13=0 and SW14=0.
3. Set SW15=1 to ARM.
4. Set SW3:0=1111 to enable all four channels.
5. Set SW7:4 for desired directions.
6. Press BTNU/D/L/R to trigger CH0/1/2/3.
7. Observe LEDs and, if available, measure the Pmod JA outputs with a logic analyzer/oscilloscope before connecting any H-bridge.

## Next stage
Stage 2 will add the 50-MHz command domain, UART register interface and per-channel CDC request/acknowledge handshakes while keeping the 100-MHz pulse engines unchanged.
