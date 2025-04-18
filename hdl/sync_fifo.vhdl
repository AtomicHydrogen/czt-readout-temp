-- Designed by: Ashwajit & Suchet
--
-- Create Date: 5/12/2024
-- Component Name: Synchronising FIFO
-- Description:
--    First In First Out buffer that is used to sync the SPI Slave interface with the rest of the circuitry
-- Dependencies:
--    Heavily interconnected with COMM FIFO and tx_packetise.
-- Revision:
--    <Code_revision_information, with revision date, content and name>
-- Additional Comments:
--    Need to know where wr_en comes from

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.std_logic_unsigned.all;

entity sync_fifo is
    generic(
        fifo_size : integer := 20;			-- Size of FIFO, i.e. no. of packets that can be stored
		packet_length : integer := 32	   -- Size of an individual packet, different for inbound and outbound FIFO
    );
   
    port (
		sync_clock : in STD_LOGIC;
		sync_clock_prev : in STD_LOGIC;
        main_clock : in STD_LOGIC;
        data_in : in STD_LOGIC_VECTOR(packet_length - 1 downto 0);     -- Data coming in to FIFO
        clear : in STD_LOGIC;														  -- Clears FIFO and resets head and tail to beginning
        wr_en : in STD_LOGIC;														  -- Write enable, controlled by the module to which data is being sent
		rd_en : in STD_LOGIC; 													  -- Read enable, controlled by module from which data is acquired
        data_out : out STD_LOGIC_VECTOR(packet_length - 1 downto 0) := (others => '0');    -- Output
		fifo_full : out STD_LOGIC := '0';								-- Active high
		fifo_empty : out STD_LOGIC := '1'
    );
    end sync_fifo;
                
architecture rtl of sync_fifo is
    type fifo_array is ARRAY (0 to fifo_size - 1) of 
							 STD_LOGIC_VECTOR(packet_length - 1 downto 0);    -- Functions as the FIFO buffer, each element in the array is a register
    signal fifo_buffer : fifo_array; 
    signal head : UNSIGNED (12 downto 0);  	           -- Decides the beginning of the buffer (i.e. where to write to). Always points to an empty register
	signal tail : UNSIGNED (12 downto 0);  		        -- Decide the  end of the buffer (i.e. where to read from) 
	signal full_temp, empty_temp : STD_LOGIC := '0';								-- Signal that stores same value as fifo_full, only there so it can be read below
	constant  zeroes : STD_LOGIC_VECTOR(packet_length - 1 downto 0) := (others => '0');
	
begin
	
	data_out <= fifo_buffer(to_integer(tail));
    process (main_clock, clear, head, tail)
    begin  
	 
		-- Clears the buffer, and resets head and tail to zero. Also makes fifo_empty 0 and fifo_full 1 since it has been cleared
    	if clear = '1' then 
        	fifo_buffer <= (others => (others => '0'));
			head <= (others => '0');
			tail <= (others => '0');

		-- Negative edge clock
		else 
			if(falling_edge(main_clock)) then
                -- If write enable is enabled
                -- data_in is written to the register pointed to by the head
                if (wr_en = '1' and full_temp = '0' and data_in /= zeroes) then
                    fifo_buffer(to_integer(head)) <= data_in;
                    -- If head reaches the end, it wraps back around, else increments
                    if (head = fifo_size - 1) then
                        head <= (others => '0');
                    else
                        head <= head + 1;
                    end if;
                end if;
            end if;

            if(falling_edge(main_clock)) then
                    -- If read enable is enabled
                    -- data_out is taken from the register pointed to by the tail
                if(sync_clock_prev = '1' and sync_clock = '0') then
                    if (rd_en = '1') then
                    
                        -- Only takes data_out from the register if fifo is not empty, else it sends zeroes. Also clears the register that is read from
                        if (not (head = tail)) then
                            -- If tail reaches the end, it wraps back around, else increments
                            if (tail = fifo_size - 1) then
                                tail <= (others => '0');
                            else 
                                tail <= tail + 1;
                            end if;					
                        end if;
                    end if;
                end if;
            end if;
        end if;
    end process;
	 
	-- Updates fifo_empty and full_temp whenever head, tail or clear is updated. Head and tail are updated
	-- synchronously but clear is async, so it also needs to be in the sensitivity list
	process(clear, head, tail) 
	begin
		-- Condition for empty fifo
		if (tail = head) then
			empty_temp <= '1'; 
			full_temp <= '0';
		-- Condition for neither empty nor full
		elsif (not (head = tail - 1 or (tail = 0 and head = fifo_size - 1))) then
			full_temp <= '0';
			empty_temp <= '0';
		-- Condition for full
		else 
			full_temp <= '1';
			empty_temp <= '0';
		end if;
	end process;
	fifo_full <= full_temp;
	fifo_empty <= empty_temp;

	
end rtl;