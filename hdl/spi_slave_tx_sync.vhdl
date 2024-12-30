-- Designed by: Suchet
--
-- Create Date: 11/10/2024
-- Component Name: SPI Slave synchronised to TX's CLK (TX: SPI Master, RX: SPI Slave). This is a bad and innacurate name.
-- Description:
--    Standard SPI Slave with variable packet width. 
--    Input needs a valid as well as ready (assumed fifo interaction). All signals are active high and will be high for exactly one cycle.
--    Inputs and outputs are of the transaction width;
-- Dependencies:
--    NA. Takes clock input
-- Revision:
--    <Code_revision_information, with revision date, content and name>
-- Additional Comments:
-- Designed to work with AXI Quad SPI in standard SPI Mode, with Automatic Slave Select, CPHA = 0, CPOL = 1; (Mode 1)
-- Sample at falling edge, shift at rising edge
-- Planned redesign for configurable mode upcoming

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use     ieee.math_real.all;

entity spi_slave_tx_sync is
    generic (
       packet_length : INTEGER := 32  
    );
    port (
       master_clk      : in  STD_LOGIC;
       slave_clk       : in  STD_LOGIC;
       reset           : in  STD_LOGIC;                                       
       miso            : out STD_LOGIC;
       mosi            : in  STD_LOGIC;	                                        
       sclk            : in  STD_LOGIC;
       ss              : in  STD_LOGIC;
	   data_in_v       : in  STD_LOGIC;
       data_in         : in  STD_LOGIC_VECTOR(31 downto 0);
       data_out        : out STD_LOGIC_VECTOR(31 downto 0);
	   data_out_v      : out STD_LOGIC;
       data_in_ready   : out STD_LOGIC;
       data_out_ready  : in  STD_LOGIC
    );
    end spi_slave_tx_sync;

architecture rtl of spi_slave_tx_sync is
	constant packet_size : INTEGER := 32;
    constant rx_count_width : integer := integer(ceil(log2(real(packet_size))));
    constant tx_count_width : integer := integer(ceil(log2(real(packet_size))));


    signal   deser_reg : STD_LOGIC_VECTOR(packet_size - 1 downto 0);
    signal   ser_reg   : STD_LOGIC_VECTOR(packet_size - 1 downto 0);
    signal   rx_count  : UNSIGNED(rx_count_width - 1 downto 0);
    signal   tx_count  : UNSIGNED(tx_count_width - 1 downto 0);

    type rx_state is (idle, rx_start, rx, rx_end, rx_false_spi);
    type tx_state is (idle, loaded, tx_start, tx, tx_end, tx_false_spi);
    type err_state is (rst, fedge);
    signal curr_err_state : err_state := rst;
    signal curr_rx_state : rx_state := idle;
    signal curr_tx_state : tx_state := idle;
    signal ser_rdy, deser_rdy, tx_ready : STD_LOGIC := '0';
	signal miso_enable : STD_LOGIC := '0'; 
    signal spi_active, spi_f_active, spi_r_active  : STD_LOGIC := '0';
    signal xclk : STD_LOGIC := '0';
    signal xclk_bar : STD_LOGIC := '1';
    signal error_reset : STD_LOGIC := '0';
    signal fsm_reset   : STD_LOGIC := '0';

    signal master_clk_bar, rx_fifo_wr_en, tx_fifo_rd_en, tx_fifo_empty, tx_fifo_full, rx_fifo_empty, rx_fifo_full: STD_LOGIC;
    signal tx_fifo_data_out : STD_LOGIC_VECTOR(packet_size -1 downto 0);


    signal mosi_sync, ss_sync, sclk_sync : STD_LOGIC;
    signal sclk_prev, ss_prev     : STD_LOGIC := '1';  -- Previous state of synchronized SCLK
    signal sclk_falling_edge, sclk_rising_edge, ss_falling_edge, ss_rising_edge : STD_LOGIC := '0';
    -- RX FIFO: NOT SCLK
    -- TX FIFO: SCLK
    component sync_fifo is
        port (
            read_clock : in STD_LOGIC;
            write_clock : in STD_LOGIC;
            data_in : in STD_LOGIC_VECTOR(packet_length - 1 downto 0);     -- Data coming in to FIFO
            clear : in STD_LOGIC;														  -- Clears FIFO and resets head and tail to beginning
            wr_en : in STD_LOGIC;														  -- Write enable, controlled by the module to which data is being sent
            rd_en : in STD_LOGIC; 													  -- Read enable, controlled by module from which data is acquired
            data_out : out STD_LOGIC_VECTOR(packet_length - 1 downto 0) := (others => '0');    -- Output
            fifo_full : out STD_LOGIC := '0';								-- Active high
            fifo_empty : out STD_LOGIC := '1'
        );
    end component;

	begin
    xclk <= sclk xor ss;
    fsm_reset <= reset or error_reset;

  --  error_correction_proc_f: process(ss, reset) begin
    --    if reset = '1' then 
      --      spi_f_active <= '0';
       -- elsif falling_edge(ss) then
        --    spi_f_active <= not(spi_f_active);
       -- end if;
   -- end process;

   -- error_correction_proc_r: process(ss, reset) begin
     --   if reset = '1' then
       --     spi_r_active <= '0';
        --elsif rising_edge(ss) then
          --  spi_r_active <= not(spi_r_active);
        --end if;
    --end process;

    error_correction_proc : process(slave_clk, reset) begin
        if reset = '1' then
            error_reset <= '0';
            curr_err_state <= rst;
        elsif falling_edge(slave_clk) then
            if curr_err_state = rst then
                error_reset <= '0';
                if ss_falling_edge = '1' then
                    curr_err_state <= fedge;
                else
                    curr_err_state <= rst;
                end if;
            elsif curr_err_state = fedge then

                if ss_rising_edge = '1' then
                    error_reset <= '1';
                    curr_err_state <= rst;
                else 
                    error_reset <= '0';
                    curr_err_state <= fedge;
                end if;
            end if;
        end if;
    end process;
            
    spi_active <= not(ss);--spi_f_active xor spi_r_active;

    rx_proc: process (xclk, fsm_reset) begin
        if fsm_reset = '1' then
            curr_rx_state <= idle;
            deser_reg     <= (others => '0');
            rx_count      <= to_unsigned(0, rx_count_width);
            rx_fifo_wr_en <= '0';
        elsif falling_edge(xclk) then
            if curr_rx_state = idle and spi_active = '1' then
                rx_fifo_wr_en <= '0';
                curr_rx_state <= rx;
                deser_reg     <= "0000000000000000000000000000000" & mosi;
                rx_count      <= to_unsigned(1, rx_count_width);
            elsif curr_rx_state = rx then
                deser_reg(packet_size -1 downto 1) <= deser_reg(packet_size - 2 downto 0);
                deser_reg(0) <= mosi;
                rx_count <= rx_count + to_unsigned(1, rx_count_width);
                if rx_count = to_unsigned(packet_size - 1, rx_count_width) then
                    curr_rx_state <= rx_end;
                    rx_fifo_wr_en <= '1' and spi_active;
                end if;
            elsif curr_rx_state = rx_end then
                rx_fifo_wr_en <= '0';
                curr_rx_state <= idle;
            end if;
        end if;
    end process;

    tx_proc : process (xclk, fsm_reset) begin
        if fsm_reset = '1' then
            miso_enable   <= '0';
            curr_tx_state <= idle;
            ser_reg       <= (others => '0');
            tx_count      <= to_unsigned(0, tx_count_width);
            tx_fifo_rd_en <= '0';
            
        elsif rising_edge(xclk) then
            if curr_tx_state = idle then
                tx_count      <= to_unsigned(0, tx_count_width);
                tx_fifo_rd_en <= '0';
                if (tx_fifo_empty) = '0' then 
                    ser_reg       <= tx_fifo_data_out;
                    miso_enable   <= '1';
                    curr_tx_state <= tx;

                else 
                    miso_enable   <= '1';
                    ser_reg       <= (others => '1');
                    curr_tx_state <= idle;

                end if;
            elsif curr_tx_state = tx then
                    miso_enable   <= '1';        
                    ser_reg(packet_size - 1 downto 1) <= ser_reg(packet_size - 2 downto 0);
                    ser_reg(0) <= '0';
                    tx_count   <= tx_count + to_unsigned(1, tx_count_width);
    
                    if tx_count = to_unsigned(packet_size - 2, tx_count_width) then
                        curr_tx_state <= tx_end;        
                        tx_fifo_rd_en <= '1' and spi_active;    
                    else 
                        curr_tx_state <= tx;
                        tx_fifo_rd_en <= '0';
                    end if;

            elsif curr_tx_state = tx_end then
                curr_tx_state <= idle;
                tx_fifo_rd_en <= '0';
                miso_enable   <= '0';

            end if;

        end if;
    end process;

    miso <= ser_reg(packet_size - 1) when miso_enable = '1' else 'Z';

    rx_fifo: sync_fifo port map (
                read_clock  => slave_clk,
                write_clock => xclk_bar,
                data_in     => deser_reg,
                wr_en       => rx_fifo_wr_en,
                rd_en       => data_out_ready,
                data_out    => data_out,
                fifo_full   => rx_fifo_full,
                fifo_empty  => rx_fifo_empty,
                clear => reset );

    tx_fifo: sync_fifo port map (
                read_clock  => xclk,
                write_clock => slave_clk,
                data_in     => data_in,
                wr_en       => data_in_v,
                rd_en       => tx_fifo_rd_en,
                data_out    => tx_fifo_data_out,
                fifo_full   => tx_fifo_full,
                fifo_empty  => tx_fifo_empty,
                clear       => reset);

    data_out_v    <= not(rx_fifo_empty);
    data_in_ready <= not(tx_fifo_full);
    xclk_bar      <= not(xclk);

    
    -- CDC Block for signals
    sampling_proc: process(slave_clk, reset)
    begin
        if reset = '1' then
				-- Initial conditions
		    sclk_prev <= '1';
            ss_prev   <= '1';
            mosi_sync <= '1';
            sclk_sync <= '1';
            ss_sync   <= '1';
        elsif falling_edge(slave_clk) then
            
            -- Edge detection for SCLK, SS
            sclk_prev <= sclk_sync;
            ss_prev   <= ss_sync;
            -- Assign synchronized outputs
            mosi_sync <= mosi;
            sclk_sync <= sclk;
            ss_sync   <= ss;

        end if;
    end process;
  

    -- Detect edges on synchronized SCLK
    sclk_rising_edge <= '1' when (sclk_prev = '0' and sclk_sync = '1') else '0';
    sclk_falling_edge <= '1' when (sclk_prev = '1' and sclk_sync = '0') else '0';
    ss_falling_edge <= '1' when (ss_prev = '1' and ss_sync = '0') else '0';
    ss_rising_edge <= '1' when (ss_prev = '0' and ss_sync = '1') else '0';
    

end rtl;
