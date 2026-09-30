# RISC16 pre-layout HOLD STA -- OpenSTA 2.0.x compatible
if {![info exists ::env(SKY130_LIB_MIN)]} {
    puts stderr "ERROR: SKY130_LIB_MIN is not set. Run: source scripts/setup_ciel_env.sh"
    exit 1
}
file mkdir reports
read_liberty $::env(SKY130_LIB_MIN)
read_verilog reports/risc16_asic_synth.v
link_design risc16_asic_top
read_sdc constraints/risc16_asic.sdc

set fp [open reports/hold_summary.rpt w]
puts $fp "RISC16 pre-layout HOLD STA"
puts $fp "Library: $::env(SKY130_LIB_MIN)"
puts $fp "Clock: 10.000 ns (100 MHz)"
puts $fp "NOTE: For OpenSTA 2.0.x, use the min-delay detailed path slack in hold_paths.rpt as the hold metric."
close $fp

report_checks -path_delay min -format full_clock_expanded \
    -fields {slew capacitance input_pin} -digits 4 \
    -group_count 10 -endpoint_count 10 > reports/hold_paths.rpt
check_setup -verbose > reports/sta_hold_checks.rpt
exit
