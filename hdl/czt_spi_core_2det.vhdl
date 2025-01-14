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
-- Testing version

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.std_logic_unsigned.all;

entity czt_spi_core_2det is
    generic(
        packet_size_tx : INTEGER := 64;
        packet_size_rx : INTEGER := 32;
        packet_length : INTEGER := 64;	   -- Size of an individual packet, different for inbound and outbound FIFO
        timestamp_size : INTEGER := 32;
        data_in_size : INTEGER := 32;
        fifo_size : INTEGER := 10;	   -- Size of FIFO, i.e. no. of packets that can be stored
        packet_in : INTEGER := 64;	   -- Size of an individual packet, different for inbound and outbound FIFO
        packet_out : INTEGER := 32;	   
        limit : INTEGER := 100;		   -- Cycles after which cmd_ready is upgraded to cmd_hp (ensures low priority commands aren't kept waiting forever)
		OUT_WIDTH : NATURAL := 32;
		alert_bits : INTEGER := 10;
		czt_spi_clk_ratio : INTEGER range 1 to 25 := 3
  );
   port(
       sys_tick   : in STD_LOGIC;
       sys_clr     : in STD_LOGIC;

       miso_pynq: out STD_LOGIC;
       mosi_pynq: in  STD_LOGIC;
       ss_pynq  : in  STD_LOGIC;
       sclk_pynq : in  STD_LOGIC;
       
       miso_czt_1 : in  STD_LOGIC;
       sclk_czt_1 : out STD_LOGIC;
       mosi_czt_1 : out STD_LOGIC;
       ss_czt_1   : out STD_LOGIC;
       
       miso_czt_0 : in  STD_LOGIC;
       sclk_czt_0 : out STD_LOGIC;
       mosi_czt_0 : out STD_LOGIC;
       ss_czt_0   : out STD_LOGIC;

       evrm_status_0 : out STD_LOGIC;
       evrm_status_1 : out STD_LOGIC
       

   );

end czt_spi_core_2det;

architecture rtl of czt_spi_core_2det is
    

    component packet_parity is
        Port (
            packet_in : in std_logic_vector(31 downto 0); -- 32-bit input packet
            packet_out : out std_logic_vector(31 downto 0) -- 32-bit output packet
        );
    end component;

    component validate_command is
        Port (
            packet_in : in std_logic_vector(31 downto 0); -- 32-bit input packet
            packet_in_v    : in std_logic;
            validation_bit : out std_logic              -- Output validation bit
        );
    end component;
    
    component watchdog is
        port (
            cmd_hp : in STD_LOGIC;     -- Data coming in from FIFO
            clock : in STD_LOGIC;
            reset : in STD_LOGIC;
            hp_alert : out STD_LOGIC   -- Timestamp of current batch, frozen at first event
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
            fifo_empty : out STD_LOGIC := '1';
            fifo_75_full : out STD_LOGIC := '0'
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
            fifo_full : out STD_LOGIC;
            cmd	: out STD_LOGIC_VECTOR(7 downto 0) := (others => '0');    -- Output
			cmd_data : out STD_LOGIC_VECTOR(15 downto 0);
            cmd_hp : out STD_LOGIC := '0';					            -- Active high, when high priority command present or queue is full or low priority
            cmd_id : out STD_LOGIC_VECTOR(0 downto 0);	                -- commands have been there for a long time
            cmd_ready : out STD_LOGIC := '0';                           -- Active high when command present in queue
            cmd_type : out STD_LOGIC_VECTOR(1 downto 0)					-- Passes on type of command (read/write)
        );
    end component;
    
    component basic_czt_spi_controller is
        generic(
            DET_ID : INTEGER;
            clk_ratio : INTEGER range 1 to 25
        );
        port (
            clk        : in  STD_LOGIC;                      -- Clock input: 100 MHz
            reset      : in  STD_LOGIC;                      -- Reset input
            wdog_hang  : in  STD_LOGIC;                      -- Highest Level Watchdog input to detect sensor hangs
            cmd        : in  STD_LOGIC_VECTOR(7 downto 0);   -- Input Command
            cmd_data   : in  STD_LOGIC_VECTOR(15 downto 0);   -- Data (if) associated with command
            cmd_hp     : in  STD_LOGIC;                      -- Command High Priority?
            cmd_ready  : in  STD_LOGIC;                      -- Is there Command Queued
            cmd_type   : in  STD_LOGIC_VECTOR(1 downto 0);   -- Queued Command Type 00 - No Read/No Write, 01 - No Read/Write, 10 - Read/No Write, 11 - Reserved
            cmd_id     : in  STD_LOGIC_VECTOR(0 downto 0);   -- Target Detector ID of command
            miso       : in  STD_LOGIC;                      -- SPI MISO                         
            mosi       : out STD_LOGIC;                      -- SPI MOSI
            sclk       : out STD_LOGIC;                      -- SCLK = SPI_CLK  (just CLK in OMS40G256 Datasheet)
            slsel      : out STD_LOGIC;                      -- SPI Slave Select
            trig       : out STD_LOGIC;                      -- Timestamp Trigger, Active Low
            fifo_deq   : out STD_LOGIC;                      -- High when dequeueing 
            data_out_v : out STD_LOGIC;                      -- Data Out Valid
            data_out   : out STD_LOGIC_VECTOR(OUT_WIDTH - 1 downto 0);   -- Output vector);
            evrm       : out STD_LOGIC
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

    component spi_slave is
        port (
           clk        : in  STD_LOGIC;
           reset      : in  STD_LOGIC;                                       
           miso       : out STD_LOGIC;
           mosi       : in  STD_LOGIC;	                                        
           sclk       : in  STD_LOGIC;
           ss         : in  STD_LOGIC;
           data_in_v  : in  STD_LOGIC;
           data_in    : in  STD_LOGIC_VECTOR(31 downto 0);
           data_out   : out STD_LOGIC_VECTOR(31 downto 0);
           data_out_v : out STD_LOGIC;
           data_in_ready   : out STD_LOGIC
        );
        end component;
    

    component tx_packetise is
        port (
            clk          : in  std_logic;
            reset        : in  std_logic;  
            fifo_75_0    : in  std_logic;
            fifo_75_1    : in  std_logic;               
            data_in_v_0  : in  std_logic;              -- Input valid signal
            data_in_v_1  : in  std_logic;
            data_in_0    : in  std_logic_vector(63 downto 0); -- 64-bit input data
            data_in_1    : in  std_logic_vector(63 downto 0);
            in_ready_0   : out std_logic;              -- Input ready signal
            in_ready_1   : out std_logic;              -- Input ready signal
    
            data_out_v   : out std_logic;              -- Output valid signal
            data_out     : out std_logic_vector(31 downto 0); -- 32-bit output data
            out_ready    : in  std_logic               -- Output ready signal
        );
    end component;
    
    
    
    signal counter : STD_LOGIC_VECTOR(alert_bits - 1 downto 0) := (others => '0');  -- Keeps track of no. of cycles that cmd_hp has been high
	
	 signal in_comm_fifo : STD_LOGIC_VECTOR (packet_size_rx -1 downto 0);
	 signal cmd_hp, cmd_ready, wr_en_comm_fifo, wr_en_comm_fifo_raw, rd_en_comm_fifo, rd_en_comm_fifo_1, rd_en_comm_fifo_0, rst_comm_fifo, rst_data_fifo, wr_en_data_fifo_0, wr_en_data_fifo_1,
            comm_fifo_ready, comm_fifo_full, fifo_75_full_0, fifo_75_full_1, rd_en_data_fifo_0, rd_en_data_fifo_1, full_data_fifo_0, full_data_fifo_1, empty_data_fifo_0, empty_data_fifo_1, rst_czt_spi, rst_clock_counter, rst_watchdog, watchdog_hang : STD_LOGIC;
	 signal cmd_type : STD_LOGIC_VECTOR (1 downto 0);
     signal cmd_id   : STD_LOGIC_VECTOR (0 downto 0);
	 signal out_comm_comm_fifo : STD_LOGIC_VECTOR (7 downto 0);
	 signal out_data_comm_fifo : STD_LOGIC_VECTOR (15 downto 0);
     signal in_validate_packet : STD_LOGIC_VECTOR(31 downto 0);
     signal valid_packet       : STD_LOGIC;
     
	 
	 signal out_czt_spi_1, out_czt_spi_0, out_czt_spi_1_parity, out_czt_spi_0_parity : STD_LOGIC_VECTOR (packet_out -1 downto 0);
	 signal timestamp   : STD_LOGIC_VECTOR (timestamp_size - 1 downto 0);
	 signal tx_parity_out, in_data_fifo_1, in_data_fifo_0, out_data_fifo_1, out_data_fifo_0 : STD_LOGIC_VECTOR (packet_size_tx - 1 downto 0);
	 signal timestamp_trig_1, timestamp_trig_0, overflow : STD_LOGIC;
     signal data_fifo_v_1, data_fifo_v_0, tx_ready, tx_pack_v : STD_LOGIC := '0';
     signal tx_pack_out : STD_LOGIC_VECTOR (31 downto 0);
     signal not_connected, temp_sig : STD_LOGIC_VECTOR (63 downto 0);
     signal not_connected_1 : STD_LOGIC;
     signal evrm_0, evrm_1, temp_ready : STD_LOGIC := '0';

		
	
	
	 begin   
    data_concat_1: data_concat port map (data_in => out_czt_spi_1_parity,
                                       timestamp => timestamp,
                                       data_to_pc => in_data_fifo_1
                                      );

    data_concat_0: data_concat port map (data_in => out_czt_spi_0_parity,
                                        timestamp => timestamp,
                                        data_to_pc => in_data_fifo_0
                                        );

    parity_calc_1: packet_parity port map (
        packet_in  => out_czt_spi_1(31 downto 2) & (comm_fifo_full & out_czt_spi_1(0)),
        packet_out => out_czt_spi_1_parity
    );

    parity_calc_0: packet_parity port map (
        packet_in  => out_czt_spi_0(31 downto 2) & (comm_fifo_full & out_czt_spi_0(0)),
        packet_out => out_czt_spi_0_parity
    );
    
    data_fifo_1: fifo port map (clock => sys_tick,
                                     data_in => in_data_fifo_1, 
                                     clear => rst_data_fifo,
                                     wr_en => wr_en_data_fifo_1, 
                                     rd_en => rd_en_data_fifo_1,
                                     data_out => out_data_fifo_1,
                                     fifo_full => full_data_fifo_1,
                                     fifo_empty => empty_data_fifo_1,
                                     fifo_75_full => fifo_75_full_1);
                                     
    data_fifo_0: fifo port map (clock => sys_tick,
                                     data_in => in_data_fifo_0, 
                                     clear => rst_data_fifo,
                                     wr_en => wr_en_data_fifo_0, 
                                     rd_en => rd_en_data_fifo_0,
                                     data_out => out_data_fifo_0,
                                     fifo_full => full_data_fifo_0,
                                     fifo_empty => empty_data_fifo_0,
                                     fifo_75_full => fifo_75_full_0);

    command_fifo_1: command_fifo port map (clock => sys_tick,
                                         command_in => in_comm_fifo,
                                         clear => rst_comm_fifo,
                                         wr_en => wr_en_comm_fifo,
                                         rd_en => rd_en_comm_fifo,
                                         fifo_full => comm_fifo_full,
                                         cmd => out_comm_comm_fifo,
										 cmd_data => out_data_comm_fifo,
                                         cmd_hp => cmd_hp,
                                         cmd_id => cmd_id,
                                         cmd_ready => cmd_ready,
                                         cmd_type => cmd_type);

    czt_spi_controller_1: basic_czt_spi_controller 
                                            generic map(DET_ID => 1, clk_ratio => czt_spi_clk_ratio)
                                            port map (clk => sys_tick,
                                                       reset => rst_czt_spi,
                                                       wdog_hang => '1',--watchdog_hang,
                                                       cmd => out_comm_comm_fifo,
                                                       cmd_data => out_data_comm_fifo,
                                                       cmd_hp => cmd_ready, --cmd_hp,
                                                       cmd_ready => cmd_ready,
                                                       cmd_id => cmd_id,
                                                       cmd_type => cmd_type,
                                                       miso => miso_czt_1,
                                                       mosi => mosi_czt_1,
                                                       sclk => sclk_czt_1,
                                                       slsel => ss_czt_1,
                                                       trig => timestamp_trig_1,
                                                       fifo_deq => rd_en_comm_fifo_1,
                                                       data_out_v => wr_en_data_fifo_1,
                                                       data_out => out_czt_spi_1,
                                                       evrm     => evrm_1);

    czt_spi_controller_0: basic_czt_spi_controller 
                                            generic map(DET_ID => 0, clk_ratio => czt_spi_clk_ratio)
                                            port map (clk => sys_tick,
                                                        reset => rst_czt_spi,
                                                        wdog_hang => '1',--watchdog_hang,
                                                        cmd => out_comm_comm_fifo,
                                                        cmd_data => out_data_comm_fifo,
                                                        cmd_hp => cmd_ready, --cmd_hp,
                                                        cmd_id => cmd_id,
                                                        cmd_ready => cmd_ready,
                                                        cmd_type => cmd_type,
                                                        miso => miso_czt_0,
                                                        mosi => mosi_czt_0,
                                                        sclk => sclk_czt_0,
                                                        slsel => ss_czt_0,
                                                        trig => timestamp_trig_0,
                                                        fifo_deq => rd_en_comm_fifo_0,
                                                        data_out_v => wr_en_data_fifo_0,
                                                        data_out => out_czt_spi_0,
                                                        evrm => evrm_0);

    
                                                                 
    clock_counter_1: clock_counter port map (clock => sys_tick,
                                             reset => rst_clock_counter,
                                             trigger => timestamp_trig_1,
                                             counter => timestamp,
                                             overflow => overflow);

    tx_packetise_1 : tx_packetise port map (clk => sys_tick,
                                            reset => sys_clr ,
                                            fifo_75_0 => fifo_75_full_0,
                                            fifo_75_1 => fifo_75_full_1, 
                                            data_in_v_1 => data_fifo_v_1,
                                            data_in_v_0 => data_fifo_v_0,
                                            in_ready_1 => rd_en_data_fifo_1,
                                            in_ready_0 => rd_en_data_fifo_0,
                                            data_in_1 => out_data_fifo_1,
                                            data_in_0 => out_data_fifo_0,
                                            data_out_v => tx_pack_v,
                                            data_out => tx_pack_out,
                                            out_ready => tx_ready);

    spi_slave_1: spi_slave port map  (clk => sys_tick,
                                      reset => sys_clr ,
                                      miso => miso_pynq,
                                      mosi => mosi_pynq,
                                      sclk => sclk_pynq,
                                      ss   => ss_pynq,
                                      data_in_v => tx_pack_v,
                                      data_in   => tx_pack_out,
                                      data_out  => in_comm_fifo,
                                      data_out_v => wr_en_comm_fifo_raw,
                                      data_in_ready => tx_ready);

    validator_1: validate_command port map (
       packet_in => in_comm_fifo,
       packet_in_v => wr_en_comm_fifo_raw,
       validation_bit => valid_packet
    );



															
															
	--temp_sig <= in_comm_fifo & in_comm_fifo;				
	rst_data_fifo <= sys_clr ;
	rst_comm_fifo <= sys_clr ;
	rst_czt_spi   <= sys_clr ;
	rst_clock_counter <= sys_clr ;
	rst_watchdog <= sys_clr ;

    rd_en_comm_fifo <= rd_en_comm_fifo_1 or rd_en_comm_fifo_0;
    data_fifo_v_1   <= not(empty_data_fifo_1);
    data_fifo_v_0   <= not(empty_data_fifo_0);

    comm_fifo_ready <= not(comm_fifo_full);

    wr_en_comm_fifo <= wr_en_comm_fifo_raw; --valid_packet;

    

    evrm_status_0 <= evrm_0;
    evrm_status_1 <= evrm_1;
    end rtl;