-- Designed by: Ashwajit
--
-- Create Date: 12/08/2024
-- Component Name: Data concatenate
-- Description:
--    Takes the timestamp and data from the FIFO buffer, concatenates them, adds zeroes to make 64 bits, and passes it on
-- Dependencies:
--    clock_counter: Takes 'counter' from the file, defined here as 'timestamp'
--    fifo -- unnamed_file: Takes data_in from FIFO
-- Revision:
--    <Code_revision_information, with revision date, content and name>
-- Additional Comments:
--    Can reduce timestamp by 1 bit, and use 56 bits (multiple of 8)

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.std_logic_unsigned.all;

entity data_concat is
    port (
       data_in : in STD_LOGIC_VECTOR(24 downto 0);     -- Data coming in from FIFO
       timestamp : in STD_LOGIC_VECTOR(31 downto 0);   -- Timestamp of current batch, frozen at first event
       data_to_pc : out STD_LOGIC_VECTOR(63 downto 0)  -- Output that is fed to PC
    );
    end data_concat;
                
architecture rtl of data_concat is

begin
	 -- 63 downto 32: timestamp
	 -- 31 downto 25: default zero
	 -- 24 downto 0: data_in
    data_to_pc <= timestamp & "0000000" & data_in;
end rtl;
            