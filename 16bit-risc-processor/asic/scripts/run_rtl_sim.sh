#!/usr/bin/env bash
set -e
mkdir -p reports
iverilog -g2012 -s tb_risc16_asic -o reports/risc16_rtl_sim \
  rtl/alu.sv rtl/regfile.sv rtl/risc16_core.sv rtl/risc16_asic_top.sv tb/tb_risc16_asic.sv
vvp reports/risc16_rtl_sim | tee reports/rtl_simulation.log
