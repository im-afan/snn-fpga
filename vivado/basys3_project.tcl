create_project -force snn_fpga ./snn_fpga -part xc7a35tcpg236-1

add_files ../src/hdl/fifo/spk_in_fifo.sv
add_files ../src/hdl/fifo/tile_idx_fifo.sv
add_files ../src/hdl/fifo/weight_fifo.sv
add_files ../src/hdl/fifo/mac_out_fifo.sv
add_files ../src/hdl/snn/lif_array.sv
add_files ../src/hdl/snn/synapse_array.sv
add_files ../src/hdl/bram/dual_port_bram.sv
add_files ../src/hdl/bram/lif_bram.sv
add_files ../src/hdl/bram/xbar_bram.sv
add_files ../src/hdl/bram/input_bram.sv
add_files ../src/hdl/bram/bram_switcher.sv
add_files ../src/hdl/scheduler/lif_scheduler.sv
add_files ../src/hdl/scheduler/xbar_scheduler.sv
add_files ../src/hdl/top.sv

add_files ../src/hdl/basys3-constraints.xdc

set_property top top [current_fileset]
