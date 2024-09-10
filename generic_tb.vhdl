library IEEE;
USE IEEE.STD_LOGIC_1164.all;
USE IEEE.NUMERIC_STD.all;
--  A testbench has no ports.
entity generic_tb is

end generic_tb;
    
    architecture behav of generic_tb is
      --  Declaration of the component that will be instantiated.
      component czt_spi_controller is

		 generic (
			  SER_WIDTH : NATURAL := 18;   -- Serialiser Register Width
			  DES_WIDTH : NATURAL := 25;   -- Deserialiser Register Width
			  OUT_WIDTH : NATURAL := 32;   -- Intermediate Output Frame Size
			  CMD_WIDTH : NATURAL := 10;    -- Detector Command Length
			  DAT_WIDTH : NATURAL := 18;   -- Detector Command associated Data Length
			  EVF_WIDTH : NATURAL := 24   -- Event Frame Width
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
        miso       : in  STD_LOGIC;                      -- SPI MISO                         
        mosi       : out STD_LOGIC;                      -- SPI MOSI
        sclk       : out STD_LOGIC;                      -- SCLK = SPI_CLK  (just CLK in OMS40G256 Datasheet)
        slsel      : out STD_LOGIC;                      -- SPI Slave Select
        trig       : out STD_LOGIC;                      -- Timestamp Trigger, Active Low
        fifo_deq   : out STD_LOGIC;                      -- High when dequeueing 
        data_out_v : out STD_LOGIC;                      -- Data Out Valid
        data_out   : out STD_LOGIC_VECTOR(OUT_WIDTH -1 downto 0);   -- Output vector, 
		  ser_reg    : out STD_LOGIC_VECTOR(SER_WIDTH -1 downto 0);
   	  lser       : out STD_LOGIC;
	     ser_enable : out STD_LOGIC;
		  cmd_reg	 : out STD_LOGIC_VECTOR(7 downto 0);
		  ser_q      : out STD_LOGIC_VECTOR(17 downto 0);
		  ser_cnt    : out UNSIGNED (4 downto 0)
                                                         -- Event format: Parity Check Status[24], ChannelX[23:20], ChannelY[19:16], Data[15:4], Res[3:0]
                                                         -- Output Frame: Frame Type[31:28], Parity Status[27], 
    );
		 end component;
    
    
      --  Specifies which entity is bound with the component.
      signal clk,reset, miso : STD_LOGIC;
		signal cmd : STD_LOGIC_VECTOR(7 downto 0) := "10000101";
		signal cmd_data : STD_LOGIC_VECTOR(15 downto 0) := "0000001111111111";
		signal cmd_type : STD_LOGIC_VECTOR(1 downto 0) := "10";
		signal mosi,sclk,slsel,trig,fifo_deq,data_out_v,lser,ser_enable : STD_LOGIC;
		signal data_out : STD_LOGIC_VECTOR(31 downto 0);
		signal ser_reg, ser_q  : STD_LOGIC_VECTOR(17 downto 0);
		signal ser_cnt  : UNSIGNED (4 downto 0);
		signal cmd_reg  : STD_LOGIC_VECTOR(7 downto 0);
		

      begin
      --  Component instantiation.
      spi_ctrlr: czt_spi_controller port map (
			  clk => clk,        
			  reset => reset,
			  wdog_hang => '1',
			  cmd => cmd,
			  cmd_data  => cmd_data,
			  cmd_hp => '1',
			  cmd_ready => '1',
			  cmd_type  => cmd_type,
			  miso => miso,
			  mosi => mosi,
			  sclk  => sclk,
			  slsel  => slsel,    
			  trig    => trig,
			  fifo_deq   => fifo_deq,
			  data_out_v => data_out_v,
			  data_out   => data_out,
			  ser_reg => ser_reg,
			  cmd_reg => cmd_reg,
			  lser => lser,
			  ser_enable => ser_enable,
			  ser_q => ser_q,
			  ser_cnt => ser_cnt
			
		);
		
      --  This process does the real job.
      ckp: process 
      begin
          clk <= '1';
          wait for 5 ns;
          clk <= '0';
          wait for 5 ns;  
      end process;
		spi_clk_p: process
		begin 
			miso <= '0';
			wait for 25 ns;
			miso <= '1';
			wait for 25ns;
		end process;
			
			
			
      
      reset <= '1', '0' after 10 ns;
		cmd <= "10000101";
		cmd_data <= "0000001111111111";
		
    end behav;