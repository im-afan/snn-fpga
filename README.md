# Spiking Neural Network on FPGA

## Features & Limitations
Compiled models for toy any-to-any SNN and MNIST are provided. We are working on a guide to train & compile custom SNNs.

## Preliminaries

Make sure Vivado and Vitis are installed and that you can run the `vivado` and `vitis` commands in your terminal. 
If you can't, you might need to [add the vivado command to your PATH](https://docs.amd.com/r/2021.2-English/ug892-vivado-design-flows-overview/Launching-the-Vivado-IDE-from-the-Command-Line-on-Windows-or-Linux).
If you are unable to add the two commands to your PATH, you can also run `{vivado install dir}/bin/vivado` and `{vitis install dir}/bin/vitis`
in place of the vivado and vitis commands.

## Setup

1. Create a `build` folder and run the build script. This builds the RTL and software code with the source directory and the compiled SNN parameters.
```
mkdir build
python3 build_project.py
```

3. Use Vivado to synthesize RTL code:
```
cd build/vivado
vivado -mode tcl -source basys3_project.tcl
```

4. After synthesis is finished, build the Vitis project:
```
cd ../vitis
vitis -s build_vitis.py
```

5. Plug your Basys3/Cmod board into your computer. Open a  serial monitor 
(PuTTY on Linux or TeraTerm on Windows) and connect to the board.

6. Open Vitis and open the `build/vitis/ws` folder. In the left bar, select 
`app_component_mnist` and click build, then run. The board will print out
the neuron spikes at every SNN simulation timestep.
