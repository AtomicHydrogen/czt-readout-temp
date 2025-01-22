# Define a procedure to create and configure the Vivado project
proc generate_design {clk_speed spi_clk_ratio jobs} {

    # Set paths
    set hdl_path "../hdl"
    set ip_name "CZT_SPI_Core"
    set xdc_file "$hdl_path/cmod_a7.xdc"

    # Create a new Vivado project for IP packaging
    set ip_project_name "ip_packaging_project"
    set ip_project_path "../hdl/ip_project"
    create_project $ip_project_name $ip_project_path -part xc7a35tcpg236-1

    # Add the HDL files for the IP to the project
    puts "Adding HDL files for $ip_name..."
    add_files -norecurse [glob -directory $hdl_path *.vhdl]

    # Package the IP
    puts "Packaging IP: $ip_name..."
    ipx::package_project -root_dir $hdl_path -vendor user -library user -name $ip_name -version 1.22 -force
    update_ip_catalog

    # Close the IP packaging project
    puts "Closing IP packaging project..."
    close_project

    # Create a new Vivado project for the block design
    set bd_project_name "cmod_a7"
    set bd_project_path "./project"
    set bd_name_wrapper "block_design_wrapper"
    create_project $bd_project_name $bd_project_path -part xc7a35tcpg236-1
    set_property board_part digilentinc.com:cmod_a7-35t:part0:1.2 [current_project]

    # Add the .xdc constraints file to the project
    puts "Adding constraints file: $xdc_file..."
    add_files -fileset constrs_1 $xdc_file

    # Create a new block design
    set bd_name "block_design"
    create_bd_design $bd_name

    # Add the clock wizard to the block design
    puts "Adding Clock Wizard..."
    create_bd_cell -type ip -vlnv xilinx.com:ip:clk_wiz:6.0 clk_wiz_0
    set_property CONFIG.PRIM_SOURCE Single_ended_clock_capable_pin [get_bd_cells clk_wiz_0]
    set_property CONFIG.CLKOUT1_REQUESTED_OUT_FREQ $clk_speed [get_bd_cells clk_wiz_0]
    set_property CONFIG.PRIM_IN_FREQ 12.0 [get_bd_cells clk_wiz_0]

    # Add the custom IP to the block design
    puts "Adding custom IP: $ip_name..."
    set_property ip_repo_paths $hdl_path [current_project]
    update_ip_catalog
    create_bd_cell -type ip -vlnv user:user:CZT_SPI_Core:1.22 czt_spi_core_0

    # Set the czt_spi_clk_ratio property for the IP
    set_property CONFIG.czt_spi_clk_ratio $spi_clk_ratio [get_bd_cells czt_spi_core_0]

    # Create ports for the block design
    puts "Creating ports..."
    # Create ports for SPI interfaces
    create_bd_port -dir I miso_czt_0
    create_bd_port -dir O mosi_czt_0
    create_bd_port -dir O sclk_czt_0
    create_bd_port -dir O ss_czt_0

    create_bd_port -dir I miso_czt_1
    create_bd_port -dir O mosi_czt_1
    create_bd_port -dir O sclk_czt_1
    create_bd_port -dir O ss_czt_1

    create_bd_port -dir O miso_pynq
    create_bd_port -dir I mosi_pynq
    create_bd_port -dir I sclk_pynq
    create_bd_port -dir I ss_pynq

    # Create ports for clock and reset
    create_bd_port -dir I clk
    create_bd_port -dir I reset

    # Connect the clock wizard to the block design ports
    puts "Connecting Clock Wizard..."
    connect_bd_net [get_bd_ports clk] [get_bd_pins clk_wiz_0/clk_in1]
    connect_bd_net [get_bd_pins clk_wiz_0/clk_out1] [get_bd_pins czt_spi_core_0/sys_tick]
    connect_bd_net [get_bd_pins clk_wiz_0/reset] [get_bd_ports reset]

    # Connect the custom IP
    puts "Connecting custom IP..."
    # Connect ports to czt_spi_core
    connect_bd_net [get_bd_ports miso_czt_0] [get_bd_pins czt_spi_core_0/miso_czt_0]
    connect_bd_net [get_bd_ports mosi_czt_0] [get_bd_pins czt_spi_core_0/mosi_czt_0]
    connect_bd_net [get_bd_ports sclk_czt_0] [get_bd_pins czt_spi_core_0/sclk_czt_0]
    connect_bd_net [get_bd_ports ss_czt_0]   [get_bd_pins czt_spi_core_0/ss_czt_0]

    connect_bd_net [get_bd_ports miso_czt_1] [get_bd_pins czt_spi_core_0/miso_czt_1]
    connect_bd_net [get_bd_ports mosi_czt_1] [get_bd_pins czt_spi_core_0/mosi_czt_1]
    connect_bd_net [get_bd_ports sclk_czt_1] [get_bd_pins czt_spi_core_0/sclk_czt_1]
    connect_bd_net [get_bd_ports ss_czt_1]   [get_bd_pins czt_spi_core_0/ss_czt_1]

    connect_bd_net [get_bd_ports miso_pynq] [get_bd_pins czt_spi_core_0/miso_pynq]
    connect_bd_net [get_bd_ports mosi_pynq] [get_bd_pins czt_spi_core_0/mosi_pynq]
    connect_bd_net [get_bd_ports sclk_pynq] [get_bd_pins czt_spi_core_0/sclk_pynq]
    connect_bd_net [get_bd_ports ss_pynq]   [get_bd_pins czt_spi_core_0/ss_pynq]

    # Connect clock and reset
    connect_bd_net [get_bd_ports reset]     [get_bd_pins czt_spi_core_0/sys_clr]

    # Validate the block design
    puts "Validating block design..."
    validate_bd_design

    # Generate the block design wrapper
    puts "Generating block design wrapper..."
    make_wrapper -files [get_files $bd_project_path/$bd_project_name.srcs/sources_1/bd/block_design/$bd_name.bd] -top
    add_files $bd_project_path/$bd_project_name.gen/sources_1/bd/block_design/hdl/$bd_name_wrapper.v
    set_property top $bd_name_wrapper [current_fileset]

    # Launch synthesis
    puts "Launching synthesis..."
    launch_runs synth_1 -jobs $jobs
    wait_on_run synth_1

    # Launch implementation
    puts "Launching implementation..."
    launch_runs impl_1 -to_step write_bitstream -jobs $jobs
    wait_on_run impl_1

    # Save the bitstream to the output files directory
    puts "Saving bitstream to outputs directory..."
    file copy -force $bd_project_path/$bd_project_name.runs/impl_1/$bd_name_wrapper.bit ../outputs/$bd_name_wrapper.bit

    # End the script
    puts "Script completed."
}

proc reset { } {
    
    # Set paths
    set project_path "./project"
    set ip_project_path "../hdl/ip_project"
    set outputs_path "../outputs"
    set scripts_path "../scripts"
    set hdl_path "../hdl"

    # Cleanup Vivado project directory
    if {[file exists $project_path]} {
        file delete -force $project_path
    }

    # Cleanup IP project directory
    if {[file exists $ip_project_path]} {
        file delete -force $ip_project_path
    }

    # Cleanup output files
    if {[file exists $outputs_path]} {
        foreach file [glob -nocomplain -directory $outputs_path *] {
            file delete -force $file
        }
    }

    # Cleanup script logs and dump files, and delete .Xil and NONE folders
    if {[file exists $scripts_path]} {
        foreach file [glob -nocomplain -directory $scripts_path *.log *.dmp] {
            file delete -force $file
        }
        # Delete .Xil folder
        set xil_path "$scripts_path/.Xil"
        if {[file exists $xil_path]} {
            file delete -force $xil_path
        }
        # Delete NONE folder
        set none_path "$scripts_path/NONE"
        if {[file exists $none_path]} {
            file delete -force $none_path
        }
    }

    # Cleanup IP Component, delete .xml files and xgui folder
    if {[file exists $hdl_path]} {
        # Delete .log and .dmp files
        foreach file [glob -nocomplain -directory $hdl_path *.log *.dmp] {
            file delete -force $file
        }
        # Delete .xml files
        foreach file [glob -nocomplain -directory $hdl_path *.xml] {
            file delete -force $file
        }
        # Delete xgui folder
        set xgui_path "$hdl_path/xgui"
        if {[file exists $xgui_path]} {
            file delete -force $xgui_path
        }
    }

    puts "Project, IP project, and related files cleanup completed."

}
