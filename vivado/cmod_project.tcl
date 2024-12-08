create_project -force fpga_risp_microblaze ./fpga_risp_microblaze -part xc7a35tcpg236-1
add_files ../src/hdl/core.sv
add_files ../src/hdl/lif.sv
add_files ../src/hdl/synapse.sv
add_files ../src/hdl/network_bram_wrapper.sv
add_files ../src/hdl/network_wrapper.sv
add_files ../src/hdl/microblaze_top.sv
add_files ../src/hdl/cmod-constraints.xdc
source ../src/hdl/microblaze_snn.tcl

make_wrapper -top -files [get_files microblaze_snn.bd]
add_files -norecurse ./fpga_risp_microblaze/fpga_risp_microblaze.gen/sources_1/bd/microblaze_snn/hdl/microblaze_snn_wrapper.v
set_property top microblaze_top [current_fileset]

launch_runs impl_1 -to_step write_bitstream -jobs 12
wait_on_run impl_1

write_hw_platform -fixed -include_bit -force -file ../vitis/microblaze_top.xsa
