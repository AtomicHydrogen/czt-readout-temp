//Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
//--------------------------------------------------------------------------------
//Tool Version: Vivado v.2022.1 (win64) Build 3526262 Mon Apr 18 15:48:16 MDT 2022
//Date        : Wed Jan 22 18:44:51 2025
//Host        : Suchets-Laptop running 64-bit major release  (build 9200)
//Command     : generate_target block_design.bd
//Design      : block_design
//Purpose     : IP block netlist
//--------------------------------------------------------------------------------
`timescale 1 ps / 1 ps

(* CORE_GENERATION_INFO = "block_design,IP_Integrator,{x_ipVendor=xilinx.com,x_ipLibrary=BlockDiagram,x_ipName=block_design,x_ipVersion=1.00.a,x_ipLanguage=VERILOG,numBlks=2,numReposBlks=2,numNonXlnxBlks=1,numHierBlks=0,maxHierDepth=0,numSysgenBlks=0,numHlsBlks=0,numHdlrefBlks=0,numPkgbdBlks=0,bdsource=USER,synth_mode=OOC_per_IP}" *) (* HW_HANDOFF = "block_design.hwdef" *) 
module block_design
   (clk,
    miso_czt_0,
    miso_czt_1,
    miso_pynq,
    mosi_czt_0,
    mosi_czt_1,
    mosi_pynq,
    reset,
    sclk_czt_0,
    sclk_czt_1,
    sclk_pynq,
    ss_czt_0,
    ss_czt_1,
    ss_pynq);
  input clk;
  input miso_czt_0;
  input miso_czt_1;
  output miso_pynq;
  output mosi_czt_0;
  output mosi_czt_1;
  input mosi_pynq;
  input reset;
  output sclk_czt_0;
  output sclk_czt_1;
  input sclk_pynq;
  output ss_czt_0;
  output ss_czt_1;
  input ss_pynq;

  wire clk_1;
  wire clk_wiz_0_clk_out1;
  wire czt_spi_core_0_miso_pynq;
  wire czt_spi_core_0_mosi_czt_0;
  wire czt_spi_core_0_mosi_czt_1;
  wire czt_spi_core_0_sclk_czt_0;
  wire czt_spi_core_0_sclk_czt_1;
  wire czt_spi_core_0_ss_czt_0;
  wire czt_spi_core_0_ss_czt_1;
  wire miso_czt_0_1;
  wire miso_czt_1_1;
  wire mosi_pynq_1;
  wire reset_1;
  wire sclk_pynq_1;
  wire ss_pynq_1;

  assign clk_1 = clk;
  assign miso_czt_0_1 = miso_czt_0;
  assign miso_czt_1_1 = miso_czt_1;
  assign miso_pynq = czt_spi_core_0_miso_pynq;
  assign mosi_czt_0 = czt_spi_core_0_mosi_czt_0;
  assign mosi_czt_1 = czt_spi_core_0_mosi_czt_1;
  assign mosi_pynq_1 = mosi_pynq;
  assign reset_1 = reset;
  assign sclk_czt_0 = czt_spi_core_0_sclk_czt_0;
  assign sclk_czt_1 = czt_spi_core_0_sclk_czt_1;
  assign sclk_pynq_1 = sclk_pynq;
  assign ss_czt_0 = czt_spi_core_0_ss_czt_0;
  assign ss_czt_1 = czt_spi_core_0_ss_czt_1;
  assign ss_pynq_1 = ss_pynq;
  block_design_clk_wiz_0_0 clk_wiz_0
       (.clk_in1(clk_1),
        .clk_out1(clk_wiz_0_clk_out1),
        .reset(reset_1));
  block_design_czt_spi_core_0_0 czt_spi_core_0
       (.miso_czt_0(miso_czt_0_1),
        .miso_czt_1(miso_czt_1_1),
        .miso_pynq(czt_spi_core_0_miso_pynq),
        .mosi_czt_0(czt_spi_core_0_mosi_czt_0),
        .mosi_czt_1(czt_spi_core_0_mosi_czt_1),
        .mosi_pynq(mosi_pynq_1),
        .sclk_czt_0(czt_spi_core_0_sclk_czt_0),
        .sclk_czt_1(czt_spi_core_0_sclk_czt_1),
        .sclk_pynq(sclk_pynq_1),
        .ss_czt_0(czt_spi_core_0_ss_czt_0),
        .ss_czt_1(czt_spi_core_0_ss_czt_1),
        .ss_pynq(ss_pynq_1),
        .sys_clr(reset_1),
        .sys_tick(clk_wiz_0_clk_out1));
endmodule
