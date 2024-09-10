-- Designed by: Ashwajit
--
-- Create Date: 12/08/2024
-- Component Name: command_fifo
-- Description:
--    Modification of standard FIFO to function as the FIFO storing commands received from the PC. 
--    Gives control signals cmd_hp, cmd_ready, and cmd_type to detector SPI to understand priority and command type, otherwise functions similarly
--    Unlike in the other FIFOs, we want this to be read depending on the urgency of the data rather than just whether the receiver feels like it,
--    hence the use of cmd_hp
-- Dependencies:
--    data_concat: Takes command_in from data_concat
--    clear, clock: Top level controlling these
--    rd_en: Likely controlled by PC interface file
--    wr_en: Likely controlled by data_concat, unclear currently
-- Revision:
--    <Code_revision_information, with revision date, content and name>
-- Additional Comments:
--    Need to know where wr_en comes from

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.std_logic_unsigned.all;

entity command_fifo is
    generic(
        fifo_size : integer := 3;	   -- Size of FIFO, i.e. no. of packets that can be stored
		packet_in : integer := 32;	   -- Size of an individual packet, different for inbound and outbound FIFO
		packet_out : integer := 32;	   
		limit : integer := 100		   -- Cycles after which cmd_ready is upgraded to cmd_hp (ensures low priority commands aren't kept waiting forever)
    );
   
    port (
		clock : in STD_LOGIC;
        command_in : in STD_LOGIC_VECTOR(packet_in - 1 downto 0);     -- Data coming in to FIFO
        clear : in STD_LOGIC;														  -- Clears FIFO and resets head and tail to beginning
        wr_en : in STD_LOGIC;														  -- Write enable, controlled by SPI_PC module
		rd_en : in STD_LOGIC; 													  -- Read enable, controlled by SPI_Det module
        cmd : out STD_LOGIC_VECTOR(7 downto 0) := (others => '0');    -- Output
		cmd_data : out STD_LOGIC_VECTOR(15 downto 0) := (others => '0');
		cmd_hp : out STD_LOGIC := '0';								-- Active high, when high priority command present or queue is full or low priority
																	-- commands have been there for a long time
		cmd_ready : out STD_LOGIC := '0';                            -- Active high when command present in queue
        cmd_type : out STD_LOGIC_VECTOR(1 downto 0)					-- Passes on type of command (read/write)
    );
    end command_fifo;
                
architecture rtl of command_fifo is
    type fifo_array is ARRAY (0 to fifo_size - 1) of 
						STD_LOGIC_VECTOR(packet_in - 1 downto 0);    -- Functions as the FIFO buffer, each element in the array is a register
    signal fifo_buffer : fifo_array; 
    signal head : INTEGER range 0 to fifo_size - 1 := 0;  	           -- Decides the beginning of the buffer (i.e. where to write to). Always points to an empty register
	signal tail : INTEGER range 0 to fifo_size - 1 := 0;  		        -- Decide the  end of the buffer (i.e. where to read from) 
	signal fifo_full : STD_LOGIC := '0';								-- Pushes cmd_hp high when high (tells SPI_Det to read as FIFO is full)
	signal fifo_empty : STD_LOGIC := '1';                               -- Used to decide cmd_ready
	signal high_p : STD_LOGIC := '0';                                   -- High when high priority command present in queue
    signal command_temp : STD_LOGIC_VECTOR(packet_in - 1 downto 0);		-- Command in FIFO currently being read (it is split into command, type, priority, etc)
    signal watchdog_full : STD_LOGIC := '0';
	 signal watchdog_timer : INTEGER range 0 to limit + 1 := 0;
begin

    cmd <= command_temp(10 downto 3);
	cmd_data <= command_temp(26 downto 11);
    cmd_type <= command_temp(2 downto 1) when watchdog_full = '0' else
					 "11";
    process (clock,clear, head, tail)
    begin  
	 -- High p : 0
	 -- cmd_type : 2 downto 1
	 -- 
		-- Clears the buffer, and resets head and tail to zero. Also makes fifo_empty 0 and fifo_full 1 since it has been cleared
    	if clear = '1' then 
        	fifo_buffer <= (others => (others => '0'));
			head <= 0;
			tail <= 0;

		-- Negative edge clock
		elsif (clock'event and clock = '0') then	
			
			-- If write enable is enabled
			-- command_in is written to the register pointed to by the head
			if (wr_en = '1' and not (fifo_full = '1')) then
				fifo_buffer(head) <= command_in;
				-- If head reaches the end, it wraps back around, else increments
				if (head = fifo_size - 1) then
					head <= 0;
				else
					head <= head + 1;
				end if;
			end if;

			-- If read enable is enabled
			-- command_temp is taken from the register pointed to by the tail
			if (rd_en = '1') then
			
				-- Only takes command_temp from the register if fifo is not empty, else it sends zeroes. Also clears the register that is read from
				if (not (head = tail)) then
					command_temp <= fifo_buffer(tail);
					fifo_buffer(tail) <= (others => '0');
					-- If tail reaches the end, it wraps back around, else increments
					if (tail = fifo_size - 1) then
						tail <= 0;
					else 
						tail <= tail + 1;
					end if;					
				else
					command_temp <= (others => '0');
				end if;
			else
				command_temp <= (others => '0');
			end if;
       end if;
    end process;
	 
	-- Updates fifo_empty and fifo_full whenever head, tail or clear is updated. Head and tail are updated
	-- synchronously but clear is async, so it also needs to be in the sensitivity list
	process(clear, head, tail) 
	begin
		-- Condition for empty fifo
		if (tail = head) then
			fifo_empty <= '1';
			fifo_full <= '0';
		-- Condition for neither empty nor full
		elsif (not (head = tail - 1 or (tail = 0 and head = fifo_size - 1))) then
			fifo_full <= '0';
			fifo_empty <= '0';
		-- Conditino for full
		else 
			fifo_full <= '1';
			fifo_empty <= '0';
		end if;
	end process;

    -- Tells detector SPI to read immediately if there's a high priority command or the queue is full
    cmd_hp <= fifo_full or high_p or watchdog_full;

    -- Tells detector SPI commands are present in queue when FIFO is not empty
    cmd_ready <= not fifo_empty;
	
	process(fifo_buffer) 
	variable high_p_var: STD_LOGIC := '0';
	begin
		high_p_var := '0';

        -- high_p is high if there is any command in the FIFO that is high priority
		for ii in 0 to fifo_size - 1 loop
			high_p_var := high_p_var or fifo_buffer(ii)(0);
		end loop;
		high_p <= high_p_var;
	end process;

    process(clock, rd_en)
    variable counter : INTEGER := 0;
    begin
        if (rd_en = '0' and fifo_empty = '0') then
            counter := counter + 1;
        else
            counter := 0;
        end if;

        if (watchdog_timer = limit) then
            if (not(rd_en = '1')) then
                watchdog_full <= '1';
					 counter := 0;
            else
                watchdog_full <= '0';
            end if;
        end if;
    watchdog_timer <= counter;
    end process;

end rtl;