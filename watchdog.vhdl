-- Designed by: Ashwajit
--
-- Create Date: 12/08/2024
-- Component Name: Watchdog
-- Description:
--    Sends an alert if cmd_hp is high for too long i.e. detector isn't processing commands when it is supposed to
-- Dependencies:
--    command_fifo: Receives cmd_hp
-- Revision:
--    <Code_revision_information, with revision date, content and name>
-- Additional Comments:
--    alert_bits can be changed depending on requirement, currently 10 (1024 cycles)

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.std_logic_unsigned.all;

entity watchdog is
    generic(
		alert_bits : integer := 10    -- Number of bits in the counter. Will wait for 2^n cycles before triggering alert
    );
    port (
        cmd_hp : in STD_LOGIC;     -- Receives from command_fifo, high if there is a high priority command in FIFO or FIFO is full
        clock : in STD_LOGIC;
		reset : in STD_LOGIC;
        hp_alert : out STD_LOGIC   -- Output, if this is high detector isn't processing urgent commands, something is wrong
    );
    end watchdog;
                
architecture rtl of watchdog is
    signal counter : STD_LOGIC_VECTOR(alert_bits - 1 downto 0) := (others => '0');  -- Keeps track of no. of cycles that cmd_hp has been high
begin

    process (clock, cmd_hp, reset)
    begin  
    
        -- Asynchronous reset being high, or cmd_hp being low (i.e. FIFO has no high priority commands and isn't full) sets counter and alert to zero
    if (cmd_hp = '0' or reset = '1') then 
        counter <= (others => '0');  
        hp_alert <= '0';

        -- Negative edge clock
    elsif (clock'event and clock = '0') then
        
            -- If counter fills up (i.e. is 2^n-1, pulls hp_alert high, only becomes low when reset or cmd_hp becomes low again)
            if counter = (counter'range => '1') then
                hp_alert <= '1';
            end if;
            
            -- counter incremented every cycle
        counter <= std_logic_vector(unsigned(counter) + 1);
        end if;
    end process;
end rtl;
            