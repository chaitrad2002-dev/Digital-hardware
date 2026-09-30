set proj_name sepm4_basys3
set proj_dir  build/$proj_name

file mkdir reports
create_project $proj_name $proj_dir -part xc7a35tcpg236-1 -force
set_property target_language Verilog [current_project]

add_files [glob rtl/*.sv]
add_files -fileset constrs_1 constraints/basys3_sepm_4ch.xdc
set_property top basys3_sepm_top [current_fileset]
update_compile_order -fileset sources_1

launch_runs synth_1 -jobs 4
wait_on_run synth_1

open_run synth_1
report_utilization -file reports/post_synth_utilization.rpt

launch_runs impl_1 -to_step write_bitstream -jobs 4
wait_on_run impl_1
open_run impl_1

report_utilization -file reports/post_impl_utilization.rpt
report_timing_summary -delay_type min_max -report_unconstrained -check_timing_verbose -max_paths 20 -file reports/post_impl_timing_summary.rpt
report_power -file reports/power.rpt
report_route_status -file reports/route_status.rpt
report_clock_utilization -file reports/clock_utilization.rpt

write_bitstream -force reports/sepm4_basys3.bit
puts "SEPM4 BUILD COMPLETE"
quit
