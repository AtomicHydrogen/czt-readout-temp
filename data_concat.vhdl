-- Designed by: Ashwajit
--
-- Create Date: 12/08/2024
-- Component Name: Data concatenate
-- Description:
--    Takes the timestamp and data from the FIFO buffer, concatenates them, and passes it on
-- Dependencies:
--    clock_counter: Takes 'counter' from the file, defined here as 'timestamp'
--    fifo: Takes data_in from FIFO
-- Revision:
--    13/8: Added generic vars so they can be changed more easily
-- Additional Comments:
--    Can reduce timestamp by 1 bit, and use 56 bits (multiple of 8)

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.std_logic_unsigned.all;

entity data_concat is
    generic(
		  packet_length : integer := 64;
		  timestamp_size : integer := 32;
		  data_in_size : integer := 32
    );
    port (
       data_in : in STD_LOGIC_VECTOR(data_in_size - 1 downto 0);     -- Data coming in from FIFO
       timestamp : in STD_LOGIC_VECTOR(timestamp_size - 1 downto 0);   -- Timestamp of current batch, frozen at first event
       data_to_pc : out STD_LOGIC_VECTOR(packet_length - 1 downto 0)  -- Output that is fed to PC
    );
    end data_concat;
                
architecture rtl of data_concat is

begin
	 -- packet_length - 1 downto 32: timestamp
	 -- 31 downto 0: data_in (as of now top 7 bits are zero)
    data_to_pc(63 downto 32) <= (others => '0');--timestamp & data_in;
    data_to_pc(31 downto 0)  <= data_in;
end rtl;
            
