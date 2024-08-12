-- Designed by: Ashwajit
--
-- Create Date: 12/08/2024
-- Component Name: Outbound FIFO
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

entity outbound_fifo is
    generic(
        fifo_size : integer := 3
    );
   
    port (
		  clock : in STD_LOGIC;
        data_in : in STD_LOGIC_VECTOR(63 downto 0);     -- Data coming in to FIFO
        clear : in STD_LOGIC;
        pc_ready : in STD_LOGIC;
        data_to_pc : out STD_LOGIC_VECTOR(63 downto 0)  -- Output that is fed to PC
    );
    end outbound_fifo;
                
architecture rtl of outbound_fifo is
    type fifo_buffer is ARRAY (0 to fifo_size - 1) of STD_LOGIC_VECTOR(63 downto 0);
    signal outbound_buffer : fifo_buffer; 
    signal head : STD_LOGIC_VECTOR(5 downto 0);   
begin
    process (clock,clear)
    begin  
	 
		 -- Asynchronous reset, sets counter_curr to zero
       if clear = '1' then 
          outbound_buffer <= (others => (others => '0'));  
			 
		 -- Positive edge clock
       elsif (clock'event and clock = '0') then
            if (pc_ready = '1') then
                for i in 1 to fifo_size - 1 loop
                    outbound_buffer(i - 1) <= outbound_buffer(i);
                end loop;            
                data_to_pc <= outbound_buffer(0);
					 if (not (unsigned(head) = 0)) then
						head <= std_logic_vector(unsigned(head) - 1);
					 end if;
            end if;
            if (not (unsigned(head) = fifo_size - 1)) then
                outbound_buffer(to_integer(unsigned(head))) <= data_in;
                head <= std_logic_vector(unsigned(head) + 1);			 
            end if;
        end if;
    end process;

end rtl;
            