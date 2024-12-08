# Spiking Neural Network on FPGA

## Preliminaries

Make sure Vivado and Vitis are installed and that you can run the `vivado` and `vitis` commands in your terminal. 
If you can't, you might need to [add the vivado command to your PATH](https://docs.amd.com/r/2021.2-English/ug892-vivado-design-flows-overview/Launching-the-Vivado-IDE-from-the-Command-Line-on-Windows-or-Linux).
If you are unable to add the two commands to your PATH, you can also run `{vivado install dir}/bin/vivado` and `{vitis install dir}/bin/vitis`
in place of the vivado and vitis commands.

## Setup

1. Download this folder and `cd` into `big-snn/vivado`:\
	`git clone git@github.com:im-afan/snn-fpga.git`\
	`cd snn-fpga`

2. Initialize a Vivado project with the HDL files in `src/hdl` called "fpga\_risp\_microblaze" 
and synthesize, then implement the hardware: 

 * For Cmod board: Run `vivado -mode tcl -source basys3_project.tcl`

 * For Basys3 board: Run `vivado -mode tcl -source cmod_project.tcl`

This step may take several minutes (up to ~30 minutes).

3. Now, `cd` into `vitis/ws`

4. Change the PATH variable in build.py to the path of the root folder of this repository.

5. Intialize the Vitis workspace by running `vitis -s build.py`.

6. Plug your Basys3/Cmod board into your computer. Open your favorite serial monitor 
(PuTTY on Linux or TeraTerm on Windows) and connect to the board.

7. Finally, open Vitis and open the `vitis/ws` folder. In the left bar, select 
`app_component` (which may take a while to load in) and click build, then run. The board will print out
the neuron activations at every SNN simulation timestep.

## Codebase explanation

`src/hdl`: hardware description language files, for synthesizing FPGA hardware
 * `network_bram_wrapper`: interface for `network_wrapper` to share BRAM with microblaze CPU
 * `core`: systolic array for spike propagation
 * `network_wrapper`: controls tiling of SNN and inputs to `core` and `lif`
 * `top_microblaze`: top-level design connecting `network_wrapper` to microblaze CPU

`src/c`: high-level C code for controlling the FPGA soft-core CPU. 
Shares memory with SNN hardware, allowing parameter, input, and output IO without resynthesyzing hardware.

`src/compile`: framework for compiling snnTorch models into C code for FPGA acceleration.
