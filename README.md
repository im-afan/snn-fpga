# Spiking Neural Network on FPGA

## Preliminaries

Make sure Vivado and Vitis are installed and that you can run the `vivado` and `vitis` commands in your terminal. 
If you can't, you might need to [add the vivado command to your PATH](https://docs.amd.com/r/2021.2-English/ug892-vivado-design-flows-overview/Launching-the-Vivado-IDE-from-the-Command-Line-on-Windows-or-Linux).
If you are unable to add the two commands to your PATH, you can also run `{vivado install dir}/bin/vivado` and `{vitis install dir}/bin/vitis`
in place of the vivado and vitis commands.

## Setup (CMOD and Basys boards)
I provided FPGA bitstream images for the CMOD and Basys boards, so synthesis and implementation is not required for these. To start, download this repo and the corresponding branch for your board:

`git clone git@github.com:im-afan/snn-fpga.git` \
`git checkout cmod`\
`cd snn-fpga`.\
Then, follow steps 1, 4, 5, and 6 in the custom build section.


## Setup (custom build)

1. Vivado is very tricky with relative paths, so you need to change the BASE_PATH variable to match your own root folder in the following locations:
`src/hdl/dual_port_bram.sv`
`src/hdl/single_port_bram.sv`
`vitis/ws/build.py`

2. Download this folder and `cd` into `big-snn/vivado`:\
	`git clone git@github.com:im-afan/snn-fpga.git`\
	`cd snn-fpga`

3. Use Vivado to synthesize/implement the project:
`cd vivado`\
`vivado -mode tcl -source cmod_project.tcl`

This step may take several minutes (up to ~30 minutes).

4. Now, create a Vitis project to program the Microblaze CPU and flash the FPGA using UART:
`cd ../vitis`\
`vitis -s build.py`.

5. Plug your Basys3/Cmod board into your computer. Open your favorite serial monitor 
(PuTTY on Linux or TeraTerm on Windows) and connect to the board.

6. Finally, open Vitis and open the `vitis/ws` folder. In the left bar, select 
`app_component_mnist` and click build, then run. The board will print out
the neuron spikes at every SNN simulation timestep.

