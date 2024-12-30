Steps to generate bitstream:
1. Unzip
2. Open Vivado 2022.1 TCL Shell
3. cd <path>, where the path points to the scripts folder, place path in quotes if it has spaces, also use / instead of \.
4. In TCL Shell: source main.tcl -notrace
5. In TCL Shell: generate_design <num_jobs> <main_clk_speed> <czt_spi_clk_ratio>
6. Check outputs folder after script completes. It should open the GUI as well.
7. In between runs, in TCL Shell: reset (resets all outputs and erases project)

Requirements for script to run:
Vivado 2022.1/2024.1
Digilent CMOD A7-35T Board Rev. 1.2 file loaded in Vivado
If you only have 1.1, change 1.2 to 1.1 on line 32 of generate_bitstream.tcl

Some other points:
If you modify the ports of the design, you will need to appropriately modify the connections in the tcl file
num_jobs: Can be upto the number of cores on your device. Ideally half the cores for Intel CPUs
main_clk_speed: FPGA Clk speed for the design
czt_spi_clk_ratio: Detector SPI speed, = main_clk_speed/(2*spi_clk_speed)