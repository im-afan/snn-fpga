
create_project -force snn_fpga ./snn_fpga -part xc7a35tcpg236-1


#add_files ../src/hdl/fifo/spk_in_fifo.sv
#add_files ../src/hdl/fifo/tile_idx_fifo.sv
#add_files ../src/hdl/fifo/weight_fifo.sv
#add_files ../src/hdl/fifo/mem_fifo.sv
##
#add_files ../src/hdl/snn/lif_array.sv
#add_files ../src/hdl/snn/lif.sv
#add_files ../src/hdl/snn/synapse_array.sv
#add_files ../src/hdl/snn/synapse.sv
##
#add_files ../src/hdl/bram/dual_port_bram.sv
#add_files ../src/hdl/bram/tile_idx_bram.sv
#add_files ../src/hdl/bram/input_bram.sv
#add_files ../src/hdl/bram/lif_bram.sv
#add_files ../src/hdl/bram/spk_in_bram.sv
#add_files ../src/hdl/bram/weight_bram.sv
##
add_files ../src/hdl/bram/mem/mlp/input_bram.mem
add_files ../src/hdl/bram/mem/mlp/mem_bram.mem
add_files ../src/hdl/bram/mem/mlp/spk_in_bram.mem
add_files ../src/hdl/bram/mem/mlp/weight_bram.mem
add_files ../src/hdl/bram/mem/mlp/tile_idx_bram.mem
#
#add_files ../src/hdl/scheduler/lif_scheduler.sv
#add_files ../src/hdl/scheduler/xbar_scheduler.sv
#add_files ../src/hdl/top.sv
#
add_files ../src/hdl/top_microblaze.sv
add_files ../src/hdl/top_standalone.sv
add_files ../src/hdl/cmod-constraints-constraints.xdc

source ../src/hdl/microblaze.tcl
make_wrapper -files [get_files microblaze.bd] -top
add_files -norecurse ./snn_fpga/snn_fpga.gen/sources_1/bd/microblaze/hdl/microblaze_wrapper.v

set_property include_dirs {../src/hdl/ ../src/hdl/bram ../src/hdl/snn ../src/hdl/fifo ../src/hdl/bram/mem} [current_fileset]

set_property top top_microblaze [current_fileset]

launch_runs impl_1 -to_step write_bitstream -jobs 12
wait_on_run impl_1

write_hw_platform -fixed -include_bit -force -file ../vitis/top_microblaze.xsa
