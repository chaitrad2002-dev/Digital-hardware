# ASIC front-end design decisions

1. **ASIC boundary:** `risc16_asic_top` contains the processor core only. Instruction and data memories are external macro interfaces. This avoids synthesizing FPGA-style inferred memories into flip-flops or treating them as standard-cell logic.
2. **Clock target:** 100 MHz / 10 ns to match the validated Basys 3 implementation target.
3. **Technology:** SkyWater SKY130 HD standard-cell library for open-source synthesis/STA.
4. **Debug:** Basys 3 switches, LEDs, loader, XDC and board wrapper are excluded. FPGA debug signals inside `risc16_core` are left unconnected by the ASIC wrapper and are removable by synthesis.
5. **Timing assumptions:** 0.2 ns clock uncertainty and 1.0 ns input/output interface delays are preliminary front-end assumptions. They are not post-layout sign-off constraints.
6. **Corners:** typical library is used for synthesis; a slow library is used for setup analysis and a fast library for hold analysis. Post-layout STA will later need extracted parasitics and CTS clocks.
