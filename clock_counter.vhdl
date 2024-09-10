-- Designed by: Ashwajit
--
-- Create Date: 12/08/2024
-- Component Name: Clock counter
-- Description:
--    For the timestamp of the data, it keeps a 32 bit counter that increments every clock tick (currently negative edge triggered)
--    Currently has an async reset
-- Dependencies:
--    NA. Takes clock input
-- Revision:
--    13/08: Added generic var for timestamp_size
-- Additional Comments:
--    We need to confirm that we should actually freeze the timestamp at a point
--		Check if overflow required
-- 	Reset needs to be applied at the beginning of every new GRB event

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.std_logic_unsigned.all;

entity clock_counter is
    generic(
		  timestamp_size : integer := 32
    );
    port (
       clock : in STD_LOGIC;                                            -- Universal clock
       reset : in STD_LOGIC;	                                        -- Async reset  
	   trigger : in STD_LOGIC;	                                        -- Control signal from detector interface when new batch starts, freezes counter, active low 
       counter : out STD_LOGIC_VECTOR(timestamp_size - 1 downto 0);     -- Output, stores the timestamp of the current batch
       overflow : out STD_LOGIC := '0'                                  -- If counter overflows
    );
    end clock_counter;
                
architecture rtl of clock_counter is
	signal counter_curr : STD_LOGIC_VECTOR(timestamp_size - 1 downto 0) := (others => '0');   -- Stores the constantly incrementing value
begin
    process (clock,reset)
    begin  
	 
		 -- Asynchronous reset, sets counter_curr and overflow to zero
       if reset = '1' then 
          counter_curr <= (others => '0');  
	  overflow <= '0';
			 
		 -- Negative edge clock
       elsif (clock'event and clock = '0') then
		 
			 -- Checks for overflow. If overflow unnecessary, remove declaration and next 3 lines
			 if counter_curr = (counter_curr'range => '1') then
					 overflow <= '1';
			 end if;
			 
			 -- counter_curr incremented
          counter_curr <= std_logic_vector(unsigned(counter_curr) + 1);
        end if;
    end process;
	 
	 -- Counter stays constant except when trigger is low, where it takes value of counter_curr
	 -- Effectively a mux connecting back on itself
counter_p : process (clock, reset) begin
	if trigger = '0' then
		if reset = '1' then 
			counter <= (others => '0');
		elsif falling_edge(clock) then 
			counter <= counter_curr;
		end if;
	end if;
    end process;
	 
end rtl;
            
