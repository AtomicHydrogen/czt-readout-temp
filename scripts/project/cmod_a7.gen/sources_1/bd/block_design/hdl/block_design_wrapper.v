//Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
//--------------------------------------------------------------------------------
//Tool Version: Vivado v.2022.1 (win64) Build 3526262 Mon Apr 18 15:48:16 MDT 2022
//Date        : Wed Jan 22 18:44:51 2025
//Host        : Suchets-Laptop running 64-bit major release  (build 9200)
//Command     : generate_target block_design_wrapper.bd
//Design      : block_design_wrapper
//Purpose     : IP block netlist
//--------------------------------------------------------------------------------
`timescale 1 ps / 1 ps

module block_design_wrapper
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

  wire clk;
  wire miso_czt_0;
  wire miso_czt_1;
  wire miso_pynq;
  wire mosi_czt_0;
  wire mosi_czt_1;
  wire mosi_pynq;
  wire reset;
  wire sclk_czt_0;
  wire sclk_czt_1;
  wire sclk_pynq;
  wire ss_czt_0;
  wire ss_czt_1;
  wire ss_pynq;

  block_design block_design_i
       (.clk(clk),
        .miso_czt_0(miso_czt_0),
        .miso_czt_1(miso_czt_1),
        .miso_pynq(miso_pynq),
        .mosi_czt_0(mosi_czt_0),
        .mosi_czt_1(mosi_czt_1),
        .mosi_pynq(mosi_pynq),
        .reset(reset),
        .sclk_czt_0(sclk_czt_0),
        .sclk_czt_1(sclk_czt_1),
        .sclk_pynq(sclk_pynq),
        .ss_czt_0(ss_czt_0),
        .ss_czt_1(ss_czt_1),
        .ss_pynq(ss_pynq));
endmodule
