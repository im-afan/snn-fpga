create_project -force snn_fpga ./snn_fpga -part xc7a35tcpg236-1


#add_files ../src/hdl/fifo/spk_in_fifo.sv
#add_files ../src/hdl/fifo/tile_idx_fifo.sv
#add_files ../src/hdl/fifo/weight_fifo.sv
#add_files ../src/hdl/fifo/mem_fifo.sv
#
#add_files ../src/hdl/snn/lif_array.sv
#add_files ../src/hdl/snn/lif.sv
#add_files ../src/hdl/snn/synapse_array.sv
#add_files ../src/hdl/snn/synapse.sv
#
#add_files ../src/hdl/bram/dual_port_bram.sv
#add_files ../src/hdl/bram/tile_idx_bram.sv
#add_files ../src/hdl/bram/input_bram.sv
#add_files ../src/hdl/bram/lif_bram.sv
#add_files ../src/hdl/bram/spk_in_bram.sv
#add_files ../src/hdl/bram/weight_bram.sv
#
add_files ../src/hdl/bram/mem/input_bram.mem
add_files ../src/hdl/bram/mem/mem_bram.mem
add_files ../src/hdl/bram/mem/spk_in_bram.mem
add_files ../src/hdl/bram/mem/weight_bram.mem
add_files ../src/hdl/bram/mem/tile_idx_bram.mem
#
#add_files ../src/hdl/scheduler/lif_scheduler.sv
#add_files ../src/hdl/scheduler/xbar_scheduler.sv
#add_files ../src/hdl/top.sv

add_files ../src/hdl/top.sv
add_files ../src/hdl/basys3-constraints.xdc

set_property include_dirs {../src/hdl/ ../src/hdl/bram ../src/hdl/snn ../src/hdl/fifo ../src/hdl/bram/mem} [current_fileset]
#set_property include_dirs {. bram snn fifo mem} [current_fileset]

set_property top top [current_fileset]
