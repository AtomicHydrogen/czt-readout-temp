-- Designed by: Ashwajit & Suchet
--
-- Create Date: 12/08/2024
-- Component Name: Top Level
-- Description:
--    Top Level FPGA file. Interconnects all components and handles external connections.
-- Dependencies:
--    All HDL files 
-- Revision:
--    Rev1, Sep 3rd, 2024
-- Additional Comments:
--    Each subsystem may potentially be configured to reset inedependently. Currently they are linked to the main reset.

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.std_logic_unsigned.all;

entity top_level is
    generic(
        packet_size_tx : INTEGER := 64;
        packet_size_rx : INTEGER := 32;
        packet_length : INTEGER := 64;	   -- Size of an individual packet, different for inbound and outbound FIFO
        timestamp_size : INTEGER := 32;
        data_in_size : INTEGER := 32;
        fifo_size : INTEGER := 3;	   -- Size of FIFO, i.e. no. of packets that can be stored
        packet_in : INTEGER := 64;	   -- Size of an individual packet, different for inbound and outbound FIFO
        packet_out : INTEGER := 32;	   
        limit : INTEGER := 100;		   -- Cycles after which cmd_ready is upgraded to cmd_hp (ensures low priority commands aren't kept waiting forever)
		  OUT_WIDTH : NATURAL := 32;
		  alert_bits : INTEGER := 10
  );
   port(
       clock    : in STD_LOGIC;
       reset    : in STD_LOGIC;
       
       rx       : in STD_LOGIC;
       miso_czt : in STD_LOGIC;

       sclk_czt : out STD_LOGIC;
       mosi_czt : out STD_LOGIC;
       ss_czt   : out STD_LOGIC;
       tx  : out STD_LOGIC
   );
end top_level;

architecture rtl of top_level is
    component watchdog is
        port (
            cmd_hp : in STD_LOGIC;     -- Data coming in from FIFO
            clock : in STD_LOGIC;
            reset : in STD_LOGIC;
            hp_alert : out STD_LOGIC   -- Timestamp of current batch, frozen at first event
        );
    end component;
	 
	 

    component UART is
    Generic (
        CLK_FREQ      : integer := 100e6;   -- system clock frequency in Hz
        BAUD_RATE     : integer := 115200; -- baud rate value
        PARITY_BIT    : string  := "none"; -- type of parity: "none", "even", "odd", "mark", "space"
        USE_DEBOUNCER : boolean := True    -- enable/disable debouncer
    );
    Port (
        -- CLOCK AND RESET
        CLK          : in  std_logic; -- system clock
        RST          : in  std_logic; -- high active synchronous reset
        -- UART INTERFACE
        UART_TXD     : out std_logic; -- serial transmit data
        UART_RXD     : in  std_logic; -- serial receive data
        -- USER DATA INPUT INTERFACE
        FIFO_DATA    : in  std_logic_vector(63 downto 0); -- 64-bit input data from FIFO
        FIFO_EMPTY   : in  std_logic; -- FIFO empty signal, effectively a valid signal
        DIN_RDY      : out std_logic; -- when DIN_RDY = 1, transmitter is ready and valid input data will be accepted for transmitting
        -- USER DATA OUTPUT INTERFACE
        DOUT         : out std_logic_vector(7 downto 0); -- output data received via UART
        DOUT_VLD     : out std_logic; -- when DOUT_VLD = 1, output data (DOUT) are valid (is assert only for one clock cycle)
        FRAME_ERROR  : out std_logic; -- when FRAME_ERROR = 1, stop bit was invalid (is assert only for one clock cycle)
        PARITY_ERROR : out std_logic  -- when PARITY_ERROR = 1, parity bit was invalid (is assert only for one clock cycle)
    );
end component;

    component fifo is
        port (
            clock : in STD_LOGIC;
            data_in : in STD_LOGIC_VECTOR(packet_length - 1 downto 0);     -- Data coming in to FIFO
            clear : in STD_LOGIC;														  -- Clears FIFO and resets head and tail to beginning
            wr_en : in STD_LOGIC;														  -- Write enable, controlled by the module to which data is being sent
            rd_en : in STD_LOGIC; 													  -- Read enable, controlled by module from which data is acquired
            data_out : out STD_LOGIC_VECTOR(packet_length - 1 downto 0) := (others => '0');    -- Output
            fifo_full : out STD_LOGIC := '0';								-- Active high
            fifo_empty : out STD_LOGIC := '1'
        );
    end component;

    component data_concat is
        port (
           data_in : in STD_LOGIC_VECTOR(data_in_size - 1 downto 0);     -- Data coming in from FIFO
           timestamp : in STD_LOGIC_VECTOR(timestamp_size - 1 downto 0);   -- Timestamp of current batch, frozen at first event
           data_to_pc : out STD_LOGIC_VECTOR(packet_length - 1 downto 0)  -- Output that is fed to PC
        );
    end component;

    component command_fifo is
      
        port (
            clock : in STD_LOGIC;
            command_in : in STD_LOGIC_VECTOR (packet_size_rx - 1 downto 0);     -- Data coming in to FIFO
            clear : in STD_LOGIC;														  -- Clears FIFO and resets head and tail to beginning
            wr_en : in STD_LOGIC;														  -- Write enable, controlled by SPI_PC module
            rd_en : in STD_LOGIC; 													  -- Read enable, controlled by SPI_Det module
            cmd	: out STD_LOGIC_VECTOR(7 downto 0) := (others => '0');    -- Output
				cmd_data : out STD_LOGIC_VECTOR(15 downto 0);
            cmd_hp : out STD_LOGIC := '0';								-- Active high, when high priority command present or queue is full or low priority                                                           -- commands have been there for a long time
            cmd_ready : out STD_LOGIC := '0';                            -- Active high when command present in queue
            cmd_type : out STD_LOGIC_VECTOR(1 downto 0)					-- Passes on type of command (read/write)
        );
    end component;
    
    component czt_spi_controller is
        port (
            clk        : in  STD_LOGIC;                      -- Clock input: 100 MHz
            reset      : in  STD_LOGIC;                      -- Reset input
            wdog_hang  : in  STD_LOGIC;                      -- Highest Level Watchdog input to detect sensor hangs
            cmd        : in  STD_LOGIC_VECTOR(7 downto 0);   -- Input Command
            cmd_data   : in  STD_LOGIC_VECTOR(15 downto 0);   -- Data (if) associated with command
            cmd_hp     : in  STD_LOGIC;                      -- Command High Priority?
            cmd_ready  : in  STD_LOGIC;                      -- Is there Command Queued
            cmd_type   : in  STD_LOGIC_VECTOR(1 downto 0);   -- Queued Command Type 00 - No Read/No Write, 01 - No Read/Write, 10 - Read/No Write, 11 - Reserved
            miso       : in  STD_LOGIC;                      -- SPI MISO                         
            mosi       : out STD_LOGIC;                      -- SPI MOSI
            sclk       : out STD_LOGIC;                      -- SCLK = SPI_CLK  (just CLK in OMS40G256 Datasheet)
            slsel      : out STD_LOGIC;                      -- SPI Slave Select
            trig       : out STD_LOGIC;                      -- Timestamp Trigger, Active Low
            fifo_deq   : out STD_LOGIC;                      -- High when dequeueing 
            data_out_v : out STD_LOGIC;                      -- Data Out Valid
            data_out   : out STD_LOGIC_VECTOR(OUT_WIDTH -1 downto 0)   -- Output vector);
        );
    end component;
    
    component clock_counter is

        port (
           clock : in STD_LOGIC;                                            -- Universal clock
           reset : in STD_LOGIC;	                                        -- Async reset  
           trigger : in STD_LOGIC;	                                        -- Control signal from detector interface when new batch starts, freezes counter, active low 
           counter : out STD_LOGIC_VECTOR(timestamp_size - 1 downto 0);     -- Output, stores the timestamp of the current batch
           overflow : out STD_LOGIC := '0'                                  -- If counter overflows
        );
    end component;
	 
	component rx_packetise is 
	Port (
		CLK   : in STD_LOGIC;
		RST   : in STD_LOGIC;
		DIN_V : in STD_LOGIC;
		DIN   : in STD_LOGIC_VECTOR (7 downto 0);
		DOUT  : out STD_LOGIC_VECTOR (31 downto 0);
		DOUT_V: out STD_LOGIC
		
	);
	end component;	
    
    signal counter : STD_LOGIC_VECTOR(alert_bits - 1 downto 0) := (others => '0');  -- Keeps track of no. of cycles that cmd_hp has been high
	
	 signal in_comm_fifo : STD_LOGIC_VECTOR (packet_size_rx -1 downto 0);
	 signal uart_rx_v, frame_error, parity_error, cmd_hp, cmd_ready, wr_en_comm_fifo, rd_en_comm_fifo, rst_comm_fifo, rst_data_fifo, wr_en_data_fifo, rd_en_data_fifo, full_data_fifo, empty_data_fifo, rst_czt_spi, rst_clock_counter, rst_watchdog, watchdog_hang : STD_LOGIC;
	 signal cmd_type : STD_LOGIC_VECTOR (1 downto 0);
	 signal out_comm_comm_fifo, uart_rx_data : STD_LOGIC_VECTOR (7 downto 0);
	 signal out_data_comm_fifo : STD_LOGIC_VECTOR (15 downto 0);
	 
	 signal out_czt_spi : STD_LOGIC_VECTOR (packet_out -1 downto 0);
	 signal timestamp   : STD_LOGIC_VECTOR (timestamp_size - 1 downto 0);
	 signal in_data_fifo, out_data_fifo : STD_LOGIC_VECTOR (packet_size_tx - 1 downto 0);
	 signal timestamp_trig, overflow : STD_LOGIC;

	
		
	
	
	 begin

                              
    data_concat_1: data_concat port map (data_in => out_czt_spi,
                                       timestamp => timestamp,
                                       data_to_pc => in_data_fifo
                                      );
    
    data_fifo_1: fifo port map (clock => clock,
                                     data_in => in_data_fifo,
                                     clear => rst_data_fifo,
                                     wr_en => wr_en_data_fifo,
                                     rd_en => rd_en_data_fifo,
                                     data_out => out_data_fifo,
                                     fifo_full => full_data_fifo,
                                     fifo_empty => empty_data_fifo);

    pc_uart_1: uart port map (clk => clock,
                              rst => reset,
										uart_txd => tx,
										uart_rxd => rx,
                               fifo_empty => empty_data_fifo,
                               fifo_data => out_data_fifo,
										 din_rdy => rd_en_data_fifo,
                               dout => uart_rx_data,
                               dout_vld => uart_rx_v,
										 frame_error => frame_error,
										 parity_error => parity_error);
	 rx_packetise_1 : rx_packetise port map (clk => clock,
														  rst => reset,
														  din_v => uart_rx_v,
														  din => uart_rx_data,
														  dout => in_comm_fifo,
														  dout_v => wr_en_comm_fifo);
														  
														  
														  
	 

    watchdog_1: watchdog port map (cmd_hp => cmd_hp,
                                   clock => clock,
                                   reset => rst_watchdog,
                                   hp_alert => watchdog_hang);

    command_fifo_1: command_fifo port map (clock => clock,
                                         command_in => in_comm_fifo,
                                         clear => rst_comm_fifo,
                                         wr_en => wr_en_comm_fifo,
                                         rd_en => rd_en_comm_fifo,
                                         cmd => out_comm_comm_fifo,
													  cmd_data => out_data_comm_fifo,
                                         cmd_hp => cmd_hp,
                                         cmd_ready => cmd_ready,
                                         cmd_type => cmd_type);

    czt_spi_controller_1: czt_spi_controller port map (clk => clock,
                                                       reset => rst_czt_spi,
                                                       wdog_hang => watchdog_hang,
                                                       cmd => out_comm_comm_fifo,
                                                       cmd_data => out_data_comm_fifo,
                                                       cmd_hp => cmd_hp,
                                                       cmd_ready => cmd_ready,
                                                       cmd_type => cmd_type,
                                                       miso => miso_czt,
                                                       mosi => mosi_czt,
                                                       sclk => sclk_czt,
                                                       slsel => ss_czt,
                                                       trig => timestamp_trig,
                                                       fifo_deq => rd_en_comm_fifo,
                                                       data_out_v => wr_en_data_fifo,
                                                       data_out => out_czt_spi);
                                                                 
    clock_counter_1: clock_counter port map (clock => clock,
                                             reset => rst_clock_counter,
                                             trigger => timestamp_trig,
                                             counter => timestamp,
                                             overflow => overflow);
															
															
															
	rst_data_fifo <= reset;
	rst_comm_fifo <= reset;
	rst_czt_spi   <= reset;
	rst_clock_counter <= reset;
	
end rtl;