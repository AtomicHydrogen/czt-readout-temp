-- Designed by: Suchet
--
-- Create Date: 11/10/2024
-- Component Name: SPI Slave
-- Description:
--    Standard SPI Slave with variable packet width.
--    Input needs a valid as well as ready (assumed fifo interaction). All signals are active high and will be high for exactly one cycle.
--    Inputs and outputs are of the transaction width;
--    This SPI Slave is asyncronous to the main clock, and will work as long as the SCLK is atleast 4 times slower than the main clock.
-- Dependencies:
--    NA. Takes clock input
-- Revision:
--    Revision 2.0 - 11/10/2024 - Updated with appropriate CDC
-- Additional Comments:
-- Designed to work with AXI Quad SPI in standard SPI Mode, with Automatic Slave Select, CPHA = 0, CPOL = 1; (Mode 1)
-- Sample at falling edge, shift at rising edge
-- 32 bit transaction width: Can be changed by changing packet_size and I/O

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.std_logic_unsigned.all;
use     ieee.math_real.all;

entity spi_slave is
    port (
       clk        : in  STD_LOGIC;
       reset      : in  STD_LOGIC;                                       
       miso       : out STD_LOGIC;
       miso_en    : out STD_LOGIC;
       mosi       : in  STD_LOGIC;	                                        
       sclk       : in  STD_LOGIC;
       ss         : in  STD_LOGIC;
	   data_in_v  : in  STD_LOGIC;
       data_in    : in  STD_LOGIC_VECTOR(31 downto 0);
       data_out   : out STD_LOGIC_VECTOR(31 downto 0);
	   data_out_v : out STD_LOGIC;
       data_in_ready   : out STD_LOGIC
       --oversampling_clk : in STD_LOGIC
    );
    end spi_slave;

architecture rtl of spi_slave is
	constant packet_size    : INTEGER := 32;
    constant rx_count_width : integer := integer(ceil(log2(real(packet_size))));
    constant tx_count_width : integer := integer(ceil(log2(real(packet_size))));


    signal deser_reg, deser_backup : STD_LOGIC_VECTOR(packet_size - 1 downto 0);
    signal   ser_reg,   ser_backup : STD_LOGIC_VECTOR(packet_size - 1 downto 0);
    signal                rx_count : UNSIGNED(rx_count_width - 1 downto 0);
    signal                tx_count : UNSIGNED(tx_count_width - 1 downto 0);

    type rx_state is (idle, rx_start, rx, rx_end);
    type tx_state is (idle, loaded, tx_start, tx, tx_end);
    signal curr_rx_state : rx_state := idle; -- RX FSM State
    signal curr_tx_state : tx_state := idle; -- TX FSM State
    signal ser_rdy, deser_rdy, tx_ready : STD_LOGIC := '0'; --TX state transition signals
    signal mosi_sync, ss_sync, sclk_sync, mosi_sync_1, sclk_sync_1, ss_sync_1 : STD_LOGIC; -- CDC Signals
    signal sclk_prev, ss_prev     : STD_LOGIC := '1';  -- Previous state of synchronized SCLK
    signal sclk_falling_edge, sclk_rising_edge, ss_falling_edge, ss_rising_edge : STD_LOGIC := '0'; -- Edge detection signals
	signal miso_enable : STD_LOGIC := '0'; 
    signal miso_protector : STD_LOGIC := '0';
	begin
    



    rx_proc: process (clk, reset) begin
        if reset = '1' then -- Restart in idle, clear all registers
            curr_rx_state <= idle;  
            deser_reg     <= (others => '0');
            rx_count      <= to_unsigned(0, rx_count_width);
            data_out      <= (others => '0');
            data_out_v    <= '0';
        elsif falling_edge(clk) then
            if curr_rx_state = idle then -- Prepare for RX and wait for SS falling edge
                data_out      <= (others => '0');
                data_out_v    <= '0';
                if(ss_falling_edge = '1') then
                    curr_rx_state <= rx;
                    deser_reg <= (others => '0');
                    rx_count  <= to_unsigned(0, rx_count_width);
                end if;
            elsif curr_rx_state = rx then -- Shift until packet_size is reached
                if(sclk_falling_edge = '1') then
                    deser_reg(packet_size -1 downto 1) <= deser_reg(packet_size - 2 downto 0);
                    deser_reg(0) <= mosi_sync;
                    rx_count <= rx_count + to_unsigned(1, rx_count_width);
                    if rx_count = to_unsigned(packet_size - 1, rx_count_width) then
                        curr_rx_state <= rx_end;
                    elsif ss_rising_edge = '1' then
                        curr_rx_state <= idle;
                    end if;
                end if;
            elsif curr_rx_state = rx_end then -- Complete RX and return to idle, push data_out_v high for exactly 1 cycle
                if ss_rising_edge = '1' then
                    if deser_reg /= "00000000000000000000000000000000" then -- Drop 0s, this is to allow padding between packets
                        data_out <= deser_reg (31 downto 0);
                        data_out_v <= '1';
                    end if;
                    curr_rx_state <= idle;
                end if;
            end if;

        end if;
    end process;

    tx_proc : process (clk, reset) begin
        if reset = '1' then -- Clear all registers and return to idle
            miso_enable <= '0';
            curr_tx_state <= idle;
            ser_reg     <= (others => '0');
            tx_count      <= to_unsigned(0, tx_count_width);
            tx_ready      <= '0';
        elsif falling_edge(clk) then
            if curr_tx_state = idle then -- Wait for data_in_v and tx_ready to be high
                miso_enable <= '0';
                if data_in_v = '1' and tx_ready = '0' then
                  tx_ready <= '1';
                  curr_tx_state <= loaded;
                  ser_reg <= data_in;
                elsif data_in_v = '1' and tx_ready = '1' then
                  tx_ready <= '0';
                  curr_tx_state <= loaded;
                  ser_reg <= data_in;
                else 
                  tx_ready <= '1';
                  curr_tx_state <= idle;
                end if;
            elsif curr_tx_state = loaded then -- Prepare for TX and wait for SS falling edge
                tx_ready <= '0';
                if (ss_falling_edge = '1') then
                    curr_tx_state <= tx;
                    tx_count      <= to_unsigned(0, tx_count_width);
					miso_enable <= '1';
                else
		     		curr_tx_state <= loaded;
			    	miso_enable <= '0';
				end if;
            elsif curr_tx_state = tx then -- Shift until packet_size is reached
                miso_enable <= '1';
                if(sclk_rising_edge = '1') then
                    ser_reg(packet_size - 1 downto 1) <= ser_reg(packet_size - 2 downto 0);
                    ser_reg(0) <= '0';
                    tx_count  <= tx_count + to_unsigned(1, tx_count_width);
                    if tx_count = to_unsigned(packet_size - 1, tx_count_width) then
                        curr_tx_state <= tx_end;
                    elsif ss_rising_edge = '1' then
                        curr_tx_state <= idle;
                        tx_ready    <= '1';
                    end if;
                end if;
            elsif curr_tx_state = tx_end then -- Complete TX and return to idle
                miso_enable <= '0';
                if ss_rising_edge = '1' then
                    curr_tx_state <= idle;
                    tx_ready <= '1';
                end if;
            end if;

        end if;
    end process;

    miso_protector <= '1' when ss_sync = '0' else '0'; -- Protect MISO when SS is high
    miso <= ser_reg(packet_size - 1);
    miso_en <= miso_enable and miso_protector;
    -- CDC Block for signals
    sampling_proc: process(clk, reset)
    begin
        if reset = '1' then
				-- Initial conditions
		    sclk_prev <= '1';
            ss_prev   <= '1';
            mosi_sync <= '1';
            sclk_sync <= '1';
            ss_sync   <= '1';
        elsif falling_edge(clk) then
            
            -- Edge detection for SCLK, SS
            sclk_prev <= sclk_sync;
            ss_prev   <= ss_sync;
            -- Assign synchronized outputs
            mosi_sync_1 <= mosi;
            sclk_sync_1 <= sclk;
            ss_sync_1   <= ss;
            mosi_sync <= mosi_sync_1;
            sclk_sync <= sclk_sync_1;
            ss_sync   <= ss_sync_1;


        end if;
    end process;



  

    -- Detect edges on synchronized SCLK
    sclk_rising_edge <= '1' when (sclk_prev = '0' and sclk_sync = '1') else '0';
    sclk_falling_edge <= '1' when (sclk_prev = '1' and sclk_sync = '0') else '0';
    ss_falling_edge <= '1' when (ss_prev = '1' and ss_sync = '0') else '0';
    ss_rising_edge <= '1' when (ss_prev = '0' and ss_sync = '1') else '0';
	 
    data_in_ready <= tx_ready;

    
end rtl;