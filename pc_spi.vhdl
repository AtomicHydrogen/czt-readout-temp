-- Designed by: Ashwajit
--
-- Create Date: 12/08/2024
-- Component Name: PC SPI
-- Description:
--    For the timestamp of the data, it keeps a 32 bit counter that increments every clock tick (currently negative edge triggered)
--    Currently has an async reset
-- Dependencies:
--    NA. Takes clock input
-- Revision:
--    <Code_revision_information, with revision date, content and name>
-- Additional Comments:
--    We need to confirm that we should actually freeze the timestamp at a point
--		Check if overflow required
-- 	Reset needs to be applied at the beginning of every new GRB event

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.std_logic_unsigned.all;

entity pc_spi is
    generic(
		  packet_size_tx : INTEGER := 64;
		  packet_size_rx : INTEGER := 32
    );
    port (
       clock : in STD_LOGIC;                                            -- Universal clock
       miso : out STD_LOGIC;
       mosi : in STD_LOGIC;	                                        -- Async reset  
       sclk : in STD_LOGIC;
       ss : in STD_LOGIC;
		 fifo_empty : in STD_LOGIC;
       data_in : in STD_LOGIC_VECTOR(packet_size_tx -1 downto 0);
       data_out : out STD_LOGIC_VECTOR(packet_size_rx -1 downto 0);
		 wr_en_cmd : out STD_LOGIC
    );
    end pc_spi;

architecture rtl of pc_spi is
    signal rd_flag : STD_LOGIC := '0';
    signal wr_flag : STD_LOGIC := '0';
	signal ser : STD_LOGIC_VECTOR(packet_size_tx -1 downto 0) := (others => '0');
	signal deser : STD_LOGIC_VECTOR(packet_size_rx -1 downto 0) := (others => '0');

begin
    
    process (sclk)
    variable rd_counter : INTEGER range 0 to packet_size_rx + 1 := 0;
    variable wr_counter : INTEGER range 0 to packet_size_tx + 1 := 0;
    begin  
        if (ss = '0') then
            if (sclk'event and sclk = '0') then
                if (mosi = '1' or rd_flag = '1') then
                    rd_flag <= '1';
                    for i in 0 to 30 loop
                        deser(i+1) <= deser(i);
                    end loop;
                    deser(0) <= mosi;
                    rd_counter := rd_counter + 1;
                    data_out <= deser (packet_size_rx -1 downto 0);
                    if (rd_counter = packet_size_rx) then
                        wr_en_cmd <= '1';
                        rd_counter := 0;
                    end if;
                else
                    data_out <= (others => '0');
                end if;

                if (wr_flag = '0') then
                    if (not (fifo_empty = '1')) then
                        ser <= data_in;
                        wr_flag <= '1';
                    else
                        ser <= (others => '0');
                    end if;
                end if;
                
                if (wr_flag = '1') then
                    wr_counter := wr_counter + 1;
                    miso <= ser(0);
                    for i in 0 to 30 loop
                        ser(i) <= ser(i+1);
                    end loop;
                    if (wr_counter = packet_size_tx + 1) then
                        wr_counter := 0;
                        wr_flag <= '0';
                    end if;
                else
                    miso <= '0';
                end if;
                        
            end if;
        end if;
    
    end process;
	 	 
end rtl;