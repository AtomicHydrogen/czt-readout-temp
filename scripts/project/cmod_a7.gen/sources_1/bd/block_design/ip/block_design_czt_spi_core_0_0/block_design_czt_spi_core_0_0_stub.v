// Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2022.1 (win64) Build 3526262 Mon Apr 18 15:48:16 MDT 2022
// Date        : Wed Jan 22 18:47:21 2025
// Host        : Suchets-Laptop running 64-bit major release  (build 9200)
// Command     : write_verilog -force -mode synth_stub {c:/Users/Suchet
//               Gopal/Desktop/cmod_project/scripts/project/cmod_a7.gen/sources_1/bd/block_design/ip/block_design_czt_spi_core_0_0/block_design_czt_spi_core_0_0_stub.v}
// Design      : block_design_czt_spi_core_0_0
// Purpose     : Stub declaration of top-level module interface
// Device      : xc7a35tcpg236-1
// --------------------------------------------------------------------------------

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// The synthesis directives are for Synopsys Synplify support to prevent IO buffer insertion.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
(* x_core_info = "czt_spi_core_2det,Vivado 2022.1" *)
module block_design_czt_spi_core_0_0(sys_tick, sys_clr, miso_pynq, mosi_pynq, ss_pynq, 
  sclk_pynq, miso_czt_1, sclk_czt_1, mosi_czt_1, ss_czt_1, miso_czt_0, sclk_czt_0, mosi_czt_0, 
  ss_czt_0)
/* synthesis syn_black_box black_box_pad_pin="sys_tick,sys_clr,miso_pynq,mosi_pynq,ss_pynq,sclk_pynq,miso_czt_1,sclk_czt_1,mosi_czt_1,ss_czt_1,miso_czt_0,sclk_czt_0,mosi_czt_0,ss_czt_0" */;
  input sys_tick;
  input sys_clr;
  output miso_pynq;
  input mosi_pynq;
  input ss_pynq;
  input sclk_pynq;
  input miso_czt_1;
  output sclk_czt_1;
  output mosi_czt_1;
  output ss_czt_1;
  input miso_czt_0;
  output sclk_czt_0;
  output mosi_czt_0;
  output ss_czt_0;
endmodule
