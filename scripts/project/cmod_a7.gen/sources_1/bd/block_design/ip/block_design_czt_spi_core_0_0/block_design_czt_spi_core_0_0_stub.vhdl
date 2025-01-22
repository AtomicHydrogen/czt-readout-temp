-- Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
-- --------------------------------------------------------------------------------
-- Tool Version: Vivado v.2022.1 (win64) Build 3526262 Mon Apr 18 15:48:16 MDT 2022
-- Date        : Wed Jan 22 18:47:21 2025
-- Host        : Suchets-Laptop running 64-bit major release  (build 9200)
-- Command     : write_vhdl -force -mode synth_stub {c:/Users/Suchet
--               Gopal/Desktop/cmod_project/scripts/project/cmod_a7.gen/sources_1/bd/block_design/ip/block_design_czt_spi_core_0_0/block_design_czt_spi_core_0_0_stub.vhdl}
-- Design      : block_design_czt_spi_core_0_0
-- Purpose     : Stub declaration of top-level module interface
-- Device      : xc7a35tcpg236-1
-- --------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity block_design_czt_spi_core_0_0 is
  Port ( 
    sys_tick : in STD_LOGIC;
    sys_clr : in STD_LOGIC;
    miso_pynq : out STD_LOGIC;
    mosi_pynq : in STD_LOGIC;
    ss_pynq : in STD_LOGIC;
    sclk_pynq : in STD_LOGIC;
    miso_czt_1 : in STD_LOGIC;
    sclk_czt_1 : out STD_LOGIC;
    mosi_czt_1 : out STD_LOGIC;
    ss_czt_1 : out STD_LOGIC;
    miso_czt_0 : in STD_LOGIC;
    sclk_czt_0 : out STD_LOGIC;
    mosi_czt_0 : out STD_LOGIC;
    ss_czt_0 : out STD_LOGIC
  );

end block_design_czt_spi_core_0_0;

architecture stub of block_design_czt_spi_core_0_0 is
attribute syn_black_box : boolean;
attribute black_box_pad_pin : string;
attribute syn_black_box of stub : architecture is true;
attribute black_box_pad_pin of stub : architecture is "sys_tick,sys_clr,miso_pynq,mosi_pynq,ss_pynq,sclk_pynq,miso_czt_1,sclk_czt_1,mosi_czt_1,ss_czt_1,miso_czt_0,sclk_czt_0,mosi_czt_0,ss_czt_0";
attribute x_core_info : string;
attribute x_core_info of stub : architecture is "czt_spi_core_2det,Vivado 2022.1";
begin
end;
