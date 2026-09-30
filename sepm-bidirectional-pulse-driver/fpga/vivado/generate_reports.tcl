file mkdir reports
open_run impl_1
report_utilization -file reports/post_impl_utilization.rpt
report_timing_summary -delay_type min_max -report_unconstrained -check_timing_verbose -max_paths 20 -file reports/post_impl_timing_summary.rpt
report_power -file reports/power.rpt
report_route_status -file reports/route_status.rpt
report_clock_utilization -file reports/clock_utilization.rpt
