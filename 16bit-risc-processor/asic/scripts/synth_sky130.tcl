# Run with: yosys -c scripts/synth_sky130.tcl
# Required environment variable:
#   SKY130_LIB_TT = path to sky130_fd_sc_hd__tt_025C_1v80.lib

yosys -import

if {![info exists ::env(SKY130_LIB_TT)]} {
    puts stderr "ERROR: Set SKY130_LIB_TT to the SKY130 HD typical liberty file."
    exit 1
}
set lib $::env(SKY130_LIB_TT)
file mkdir reports

read_verilog -sv rtl/alu.sv rtl/regfile.sv rtl/risc16_core.sv rtl/risc16_asic_top.sv
hierarchy -check -top risc16_asic_top

# Generic synthesis and optimization.
yosys proc
flatten
opt
memory
opt
fsm
opt
techmap
opt

# Map flops and combinational logic into SKY130 HD standard cells.
dfflibmap -liberty $lib
abc -liberty $lib
clean -purge

check
tee -o reports/synthesis_stat.rpt stat -liberty $lib
write_verilog -noattr -noexpr -nodec reports/risc16_asic_synth.v
write_json reports/risc16_asic_synth.json
