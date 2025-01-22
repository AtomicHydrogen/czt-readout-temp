-- (c) Copyright 1995-2025 Xilinx, Inc. All rights reserved.
-- 
-- This file contains confidential and proprietary information
-- of Xilinx, Inc. and is protected under U.S. and
-- international copyright and other intellectual property
-- laws.
-- 
-- DISCLAIMER
-- This disclaimer is not a license and does not grant any
-- rights to the materials distributed herewith. Except as
-- otherwise provided in a valid license issued to you by
-- Xilinx, and to the maximum extent permitted by applicable
-- law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
-- WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES
-- AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
-- BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
-- INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
-- (2) Xilinx shall not be liable (whether in contract or tort,
-- including negligence, or under any other theory of
-- liability) for any loss or damage of any kind or nature
-- related to, arising under or in connection with these
-- materials, including for any direct, or any indirect,
-- special, incidental, or consequential loss or damage
-- (including loss of data, profits, goodwill, or any type of
-- loss or damage suffered as a result of any action brought
-- by a third party) even if such damage or loss was
-- reasonably foreseeable or Xilinx had been advised of the
-- possibility of the same.
-- 
-- CRITICAL APPLICATIONS
-- Xilinx products are not designed or intended to be fail-
-- safe, or for use in any application requiring fail-safe
-- performance, such as life-support or safety devices or
-- systems, Class III medical devices, nuclear facilities,
-- applications related to the deployment of airbags, or any
-- other applications that could lead to death, personal
-- injury, or severe property or environmental damage
-- (individually and collectively, "Critical
-- Applications"). Customer assumes the sole risk and
-- liability of any use of Xilinx products in Critical
-- Applications, subject only to applicable laws and
-- regulations governing limitations on product liability.
-- 
-- THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
-- PART OF THIS FILE AT ALL TIMES.
-- 
-- DO NOT MODIFY THIS FILE.

-- IP VLNV: user:user:CZT_SPI_Core:1.22
-- IP Revision: 1

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY block_design_czt_spi_core_0_0 IS
  PORT (
    sys_tick : IN STD_LOGIC;
    sys_clr : IN STD_LOGIC;
    miso_pynq : OUT STD_LOGIC;
    mosi_pynq : IN STD_LOGIC;
    ss_pynq : IN STD_LOGIC;
    sclk_pynq : IN STD_LOGIC;
    miso_czt_1 : IN STD_LOGIC;
    sclk_czt_1 : OUT STD_LOGIC;
    mosi_czt_1 : OUT STD_LOGIC;
    ss_czt_1 : OUT STD_LOGIC;
    miso_czt_0 : IN STD_LOGIC;
    sclk_czt_0 : OUT STD_LOGIC;
    mosi_czt_0 : OUT STD_LOGIC;
    ss_czt_0 : OUT STD_LOGIC
  );
END block_design_czt_spi_core_0_0;

ARCHITECTURE block_design_czt_spi_core_0_0_arch OF block_design_czt_spi_core_0_0 IS
  ATTRIBUTE DowngradeIPIdentifiedWarnings : STRING;
  ATTRIBUTE DowngradeIPIdentifiedWarnings OF block_design_czt_spi_core_0_0_arch: ARCHITECTURE IS "yes";
  COMPONENT czt_spi_core_2det IS
    GENERIC (
      packet_size_tx : INTEGER;
      packet_size_rx : INTEGER;
      packet_length : INTEGER;
      timestamp_size : INTEGER;
      data_in_size : INTEGER;
      fifo_size : INTEGER;
      packet_in : INTEGER;
      packet_out : INTEGER;
      limit : INTEGER;
      OUT_WIDTH : INTEGER;
      alert_bits : INTEGER;
      czt_spi_clk_ratio : INTEGER
    );
    PORT (
      sys_tick : IN STD_LOGIC;
      sys_clr : IN STD_LOGIC;
      miso_pynq : OUT STD_LOGIC;
      mosi_pynq : IN STD_LOGIC;
      ss_pynq : IN STD_LOGIC;
      sclk_pynq : IN STD_LOGIC;
      miso_czt_1 : IN STD_LOGIC;
      sclk_czt_1 : OUT STD_LOGIC;
      mosi_czt_1 : OUT STD_LOGIC;
      ss_czt_1 : OUT STD_LOGIC;
      miso_czt_0 : IN STD_LOGIC;
      sclk_czt_0 : OUT STD_LOGIC;
      mosi_czt_0 : OUT STD_LOGIC;
      ss_czt_0 : OUT STD_LOGIC
    );
  END COMPONENT czt_spi_core_2det;
  ATTRIBUTE X_CORE_INFO : STRING;
  ATTRIBUTE X_CORE_INFO OF block_design_czt_spi_core_0_0_arch: ARCHITECTURE IS "czt_spi_core_2det,Vivado 2022.1";
  ATTRIBUTE CHECK_LICENSE_TYPE : STRING;
  ATTRIBUTE CHECK_LICENSE_TYPE OF block_design_czt_spi_core_0_0_arch : ARCHITECTURE IS "block_design_czt_spi_core_0_0,czt_spi_core_2det,{}";
  ATTRIBUTE IP_DEFINITION_SOURCE : STRING;
  ATTRIBUTE IP_DEFINITION_SOURCE OF block_design_czt_spi_core_0_0_arch: ARCHITECTURE IS "package_project";
BEGIN
  U0 : czt_spi_core_2det
    GENERIC MAP (
      packet_size_tx => 64,
      packet_size_rx => 32,
      packet_length => 64,
      timestamp_size => 32,
      data_in_size => 32,
      fifo_size => 10,
      packet_in => 64,
      packet_out => 32,
      limit => 100,
      OUT_WIDTH => 32,
      alert_bits => 10,
      czt_spi_clk_ratio => 3
    )
    PORT MAP (
      sys_tick => sys_tick,
      sys_clr => sys_clr,
      miso_pynq => miso_pynq,
      mosi_pynq => mosi_pynq,
      ss_pynq => ss_pynq,
      sclk_pynq => sclk_pynq,
      miso_czt_1 => miso_czt_1,
      sclk_czt_1 => sclk_czt_1,
      mosi_czt_1 => mosi_czt_1,
      ss_czt_1 => ss_czt_1,
      miso_czt_0 => miso_czt_0,
      sclk_czt_0 => sclk_czt_0,
      mosi_czt_0 => mosi_czt_0,
      ss_czt_0 => ss_czt_0
    );
END block_design_czt_spi_core_0_0_arch;
