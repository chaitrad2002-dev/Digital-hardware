set proj_name sepm4_sim
set proj_dir  build/$proj_name

create_project $proj_name $proj_dir -part xc7a35tcpg236-1 -force
set_property target_language Verilog [current_project]

add_files [glob rtl/*.sv]
add_files -fileset sim_1 tb/tb_sepm_4ch_core.sv
set_property top tb_sepm_4ch_core [get_filesets sim_1]

update_compile_order -fileset sources_1
update_compile_order -fileset sim_1

launch_simulation
run all
quit
