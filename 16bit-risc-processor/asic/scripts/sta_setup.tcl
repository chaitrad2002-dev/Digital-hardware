# RISC16 pre-layout SETUP STA -- OpenSTA 2.0.x compatible
if {![info exists ::env(SKY130_LIB_MAX)]} {
    puts stderr "ERROR: SKY130_LIB_MAX is not set. Run: source scripts/setup_ciel_env.sh"
    exit 1
}
file mkdir reports
read_liberty $::env(SKY130_LIB_MAX)
read_verilog reports/risc16_asic_synth.v
link_design risc16_asic_top
read_sdc constraints/risc16_asic.sdc

set fp [open reports/setup_summary.rpt w]
puts $fp "RISC16 pre-layout SETUP STA"
puts $fp "Library: $::env(SKY130_LIB_MAX)"
puts $fp "Clock: 10.000 ns (100 MHz)"
close $fp

report_checks -path_delay max -format full_clock_expanded \
    -fields {slew capacitance input_pin} -digits 4 \
    -group_count 10 -endpoint_count 10 > reports/setup_paths.rpt
report_worst_slack >> reports/setup_summary.rpt
report_tns >> reports/setup_summary.rpt
check_setup -verbose > reports/sta_setup_checks.rpt
exit
