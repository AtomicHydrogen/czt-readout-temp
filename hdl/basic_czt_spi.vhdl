-- Designed by: Suchet Gopal
--
-- Create Date: 12/08/2024
-- Component Name: CZT SPI Interfacing Module
-- Description:
--    Main SPI module to source, control timestamp and pass data through for processing.
--    Active Events (Pull SS low, Send Commands) : At RISING_EDGE of SPI_CLK
--    Passive Events (Sample Data)               : At FALLING_EDGE of SPI_CLK
--    Also contains a significant amount of steering logic to do the following:
--    Put Detector in Event Read Mode (EVRM) if no command are pending
--    Take Detector out of EVRM if commands need to be sent urgently
--    Based on a watchdog timer - Reset the detector in case of a bug
--    Besides this, it also returns ACKs for all commands and Data Writes and writes out Data and Events received
-- Dependencies:
--    None
-- Revision:
--    Rev2, Oct 10th, 2024
-- Additional Comments:
--    Timestamp triggering not yet implemented
--    Will likely require many changes to actually work
--    Only uploading this due to people pressuring me to.
--    Too lazy to comment everything rn.


-- Import IEEE libraries
library IEEE;
use IEEE.STD_LOGIC_1164.ALL; --Standard Logic Library
use IEEE.NUMERIC_STD.ALL;    --For Numerical datatypes

-- Entity declaration
entity basic_czt_spi_controller is

    generic (
        SER_WIDTH : NATURAL := 18;   -- Serialiser Register Width
        DES_WIDTH : NATURAL := 25;   -- Deserialiser Register Width
        OUT_WIDTH : NATURAL := 32;   -- Intermediate Output Frame Size
        CMD_WIDTH : NATURAL := 10;    -- Detector Command Length
        DAT_WIDTH : NATURAL := 18;   -- Detector Command associated Data Length
        EVF_WIDTH : NATURAL := 24;   -- Event Frame Width
        DET_ID    : INTEGER := 1;
        clk_ratio : INTEGER range 1 to 25  := 3 -- SCLK RATIO: CURRENTLY 10 => 10 MHz SPI
                                                          -- clk_ratio = f_board/(2 x f_spi)
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
        data_out   : out STD_LOGIC_VECTOR(OUT_WIDTH -1 downto 0);
        evrm       : out STD_LOGIC
           -- Output vector, 
		  --ser_reg    : out STD_LOGIC_VECTOR(SER_WIDTH -1 downto 0);
   	  --lser       : out STD_LOGIC;
	     --ser_enable : out STD_LOGIC;
		  --cmd_reg	 : out STD_LOGIC_VECTOR(7 downto 0);
		  --ser_q      : out STD_LOGIC_VECTOR(17 downto 0);
		 -- ser_cnt    : out UNSIGNED (4 downto 0)
                                                         -- Event format: Parity Check Status[24], ChannelX[23:20], ChannelY[19:16], Data[15:4], Res[3:0]
                                                         -- Output Frame: Frame Type[31:28], Parity Status[27], 
                                                        -- frame format:
                                                        --Frame Type: [31:29]
                                                        --Parity         : [28]
                                                        --Command : [27:29]
                                                        --Data          : [19:4]
                                                        --Parity         : [3]
                                                        --Reserved   : [2:0]
    );
end basic_czt_spi_controller;

-- Architecture body
architecture rtl of basic_czt_spi_controller is
    --States Enum defintion
    type c_state is (start, rx, tx, exist_check, exist_check_fail, busy_check, busy_check_fail, rx_init, tx_init, rx_end, tx_end, fifo_deque);

    constant id : STD_LOGIC_VECTOR(0 downto 0) := std_logic_vector (to_unsigned(DET_ID, 1));

    signal curr_proc : STD_LOGIC_VECTOR (2 downto 0) := "000"; -- Describes the overall state of the SPI Controller
    --CURR PROC/Frame Type:
    --000 :             IDLE
    --001 :        CMD CYCLE
    --010 :  DATA READ CYCLE
    --011 : DATA WRITE CYCLE
    --100 : EVENT READ CYCLE
    --101 :      FORCE BREAK DEPRECATED
    --110 :    FORCE EVRM ON DEPRECATED
    --111 :   FORCE EVRM OFF DEPRECATED

    --Signal Declarations
    
    signal present_substate : c_state := start; -- Current Controller Lowest Level State under a given process

    signal des_sh_reg     : STD_LOGIC_VECTOR (DES_WIDTH - 1 downto 0) := (others => '0');  -- Deserialiser Shift Register
    signal des_count      : UNSIGNED (4 downto 0):= to_unsigned(0, 5);
    signal des_en         : STD_LOGIC := '0';

    signal ser_sh_reg     : STD_LOGIC_VECTOR (SER_WIDTH - 1 downto 0) := (others => '0');  --   Serialiser Shift register
    signal ser_queue      : STD_LOGIC_VECTOR (SER_WIDTH - 1 downto 0) := (others => '0');  --   Loading Register
    signal ser_count      : UNSIGNED (4 downto 0):= to_unsigned(0, 5);       -- Bit counter
    signal ser_en         : STD_LOGIC := '0';
    signal load_ser       : STD_LOGIC := '0';
    signal ser_out        : STD_LOGIC;                        -- Serialiser Output
	 --signal mosi_buff		  : STD_LOGIC := '0';

    signal ser_cmd_reg    : STD_LOGIC_VECTOR(CMD_WIDTH -1 downto 0); -- Command TX Packet Holding Register
    signal ser_data_reg   : STD_LOGIC_VECTOR (SER_WIDTH -1 downto 0); --    Data TX Packet Holding Register
    signal cmd_type_reg   : STD_LOGIC_VECTOR (1 downto 0);              -- Command Type Holding Register

    signal wdog_warning   : STD_LOGIC := '0'; -- Active High if detector hang watchdog ever gets triggered
	signal clr_warning    : STD_LOGIC := '0'; -- If WDOG WARNING has been dealth with

    signal clk_cnt        : UNSIGNED (4 downto 0) := to_unsigned(0, 5); -- CLK Divider

    signal spi_clk        : STD_LOGIC; -- SCLK
    signal spi_clk_rise   : STD_LOGIC := '0'; -- Determine SCLK rising edges - written for a falling edge trig'd main circuit
    signal spi_clk_fall   : STD_LOGIC := '0'; -- Determine SCLK falling edges - also written for a falling edge trig'd main circuit

    signal evrm_status    : STD_LOGIC := '0'; -- Sensor EVRM state according to the SPI Controller (1 for ON, 0 for OFF)



    -- signal cmd_number     : UNSIGNED (4 downto 0) := to_unsigned(0, 5);

    function xor_reduce(vec: std_logic_vector) return std_logic is -- XOR_REDUCE FUNC. for parity bit calc.
        variable result : std_logic := '0';
    begin
        for i in vec'range loop
            result := result xor vec(i);
        end loop;
        return result;
    end function xor_reduce;

begin
    spi_main: process (clk, reset)
    begin
        if reset = '1' then                      -- Determine all signals at reset
            fifo_deq         <= '0';
            present_substate <= start;
            ser_queue        <= (others => '0');
            ser_cmd_reg      <= (others => '0');
            ser_data_reg     <= (others => '0');
            ser_sh_reg       <= (others => '1');
            --mosi_buff        <= '1';            -- Have taken MOSI = '1' when not in use
            slsel            <= '1';            
            trig             <= '1';
            data_out_v       <= '0';
            data_out         <= (others => '0');
			evrm_status 	 <= '0';
			curr_proc        <= "000";


            -- cmd_number       <= to_unsigned(0, 5);

        elsif falling_edge(clk) then
            case present_substate is
                when start => 
                    -- Static Signals Start
                    present_substate <= start;
                    ser_queue        <= (others => '0');
                    ser_cmd_reg      <= (others => '0');
                    ser_data_reg     <= (others => '0');
                    ser_sh_reg       <= (others => '1');
                    --mosi_buff        <= '1';
                    slsel            <= '1';
                    trig             <= '1';
                    data_out_v       <= '0';
                    data_out         <= (others => '0');
                    
						 
                    -- Static Signals End
                    if cmd_hp = '1' and cmd_id = id then

                        fifo_deq         <= '0';
                        present_substate <= busy_check; -- Try to send command
                        ser_cmd_reg  <= '0' & (cmd & (xor_reduce(cmd))); -- Holding register for cmd
                        ser_data_reg <= '1' & (cmd_data & not(xor_reduce(cmd_data))); -- Holding register for data
                        cmd_type_reg <= cmd_type; -- For proper command execution
                        curr_proc <= "001"; -- Change curr proc to reflect command execution

                        -- cmd_number <= cmd_number + to_unsigned(1, 5);

                    else
                        if evrm_status = '1' then
                            fifo_deq <= '0';
                            present_substate <= exist_check;
                            
                        elsif cmd_ready = '1' and cmd_id = id then -- COMMAND OF NORMAL PRIORITY AND NOT IN EVRM, LOAD COMMAND
                            fifo_deq         <= '0';
                            present_substate <= busy_check;
                            ser_cmd_reg  <= '0' & (cmd & (xor_reduce(cmd)));
                            ser_data_reg <= '1' & (cmd_data & not(xor_reduce(cmd_data)));
                            cmd_type_reg <= cmd_type;
                            curr_proc <= "001";

                            -- cmd_number <= cmd_number + to_unsigned(1, 5);

                        else  
                            fifo_deq         <= '0';
                            present_substate <= start;
                        end if;
                    end if;
                when exist_check =>
                    fifo_deq         <= '0';
                    data_out_v       <= '0';
                    if spi_clk_rise = '1' then
                        slsel <= '0'; -- Push SS LOW at SPI_CLK rising edge, to start the process of checking
                        present_substate <= rx_init;
                        ser_sh_reg <= (others => '1'); -- Make MOSI '1' for data cycle
                    end if;
                when rx_init =>
                    des_count <= (others => '0');
                    des_sh_reg <= (others => '0');
                    if spi_clk_fall = '1' then
                        if miso = '0' then -- If the Detector has an event/Is ready for Data Readout, start RX
                            present_substate <= rx;
                            if curr_proc = "000" then
                                curr_proc <= "100"; -- Move from Idle to Event Readout mode
								--trig <= '0';
                            end if;
                        else 
                            present_substate <= exist_check_fail; -- Deal with failure :'(
                        end if;
                    end if;
                when exist_check_fail => -- Coping with failure and rejection :'(
                    if spi_clk_rise = '1' then -- Only pull SS HIGH at a rising edge of SPI_CLK
                        slsel <= '1';
                        if curr_proc = "000" then -- If originaly in Idle, try to get a CMD sent since no events in detector
                            present_substate <= start;
                        else
                            present_substate <= exist_check; -- Otherwise retry
                        end if;
                    else
                        present_substate <= exist_check_fail;
                    end if;
                        
                when rx =>
					--trig <= '1';
                    if spi_clk_fall = '1' then
                        des_sh_reg(DES_WIDTH -1 downto 1) <= des_sh_reg(DES_WIDTH -2 downto 0); -- Shift Left
                        des_sh_reg(0)                 <= miso;              -- Clock MISO into the register
                        des_count <= des_count + to_unsigned(1, 5);
                        if des_count = to_unsigned(DES_WIDTH - 1, 5) and curr_proc = "100" then -- If we expect an Event Read
                            present_substate <= rx_end;
                        elsif des_count = to_unsigned(DAT_WIDTH - 2, 5) and curr_proc = "010" then -- If we expect a Data Read
                            present_substate <= rx_end;
                        else
                            present_substate <= rx;
                        end if;
                    else
                        present_substate <= rx;
                    end if;
                when rx_end =>
                    if spi_clk_rise = '1' then
                        slsel <= '1';
                        if curr_proc = "100" then -- If we expect an Event Read
                            data_out_v <= '1';
                            data_out   <= curr_proc & ('1' &(des_sh_reg &"00" & (id))); -- Event Readout
                            curr_proc  <= "000";
                            present_substate <= start;
                        elsif  curr_proc = "010" then -- If we expect a Data Read
                            fifo_deq <= '1';
                            data_out_v <= '1';
                            data_out   <= curr_proc & ('1' & (ser_cmd_reg(CMD_WIDTH -2 downto 1) &(des_sh_reg(16 downto 0) &("00" & (id))))); -- Data Readout
                            curr_proc  <= "000";
                            present_substate <= fifo_deque;

                            -- cmd_number <= cmd_number + to_unsigned(1, 5);
                            
                        end if;
                    else 
                        present_substate <= rx_end;
                    end if;
                when busy_check =>
                    fifo_deq         <= '0';
                    data_out_v       <= '0';
                    if spi_clk_rise = '1' then
                        slsel <= '0'; -- Push SS LOW on SPI_CLK rising edges only
                        present_substate <= tx_init;
                        --if curr_proc = "001" then
                          --  mosi_buff <= '0'; -- Acc. to Detector Spec, 0 for CMD/COMM cycles
                        --else 
                         --   mosi_buff <= '1'; -- Acc. to Detector Spec, 1 for Data Write cycles
                        -- end if;
                        if curr_proc = "001" then
                            ser_sh_reg <= ser_cmd_reg & "00000000"; -- Load CMD
                        else 
                            ser_sh_reg <= ser_data_reg; -- Load Data
                        end if;
                    else 
                        present_substate <= busy_check;
                    end if;

                when busy_check_fail =>
                    if spi_clk_rise = '1' then
                        slsel <= '1';
                        present_substate <= busy_check;
                    else 
                        present_substate <= busy_check_fail;
                    end if;
                            
            
                when tx_init =>
                    if spi_clk_fall = '1' then
                        if miso = '0' then 
                            present_substate <= tx;
                            ser_count <= to_unsigned(0,5);  -- Increment count
                        elsif ser_cmd_reg(CMD_WIDTH -2 downto 1) /= "00000010" and ser_cmd_reg(CMD_WIDTH -2 downto 1) /= "00000101" then
                            present_substate <= busy_check_fail;
                        else
                            present_substate <= tx;
                            ser_count <= to_unsigned(0,5);  -- Increment count
                        end if;
                    else 
                        present_substate <= tx_init;
                    end if;
                
                when tx => -- Same Logic as RX
                    if spi_clk_rise = '1' then
                        ser_sh_reg <= ser_sh_reg(SER_WIDTH-2 downto 0) & '0';  -- Shift left
                        ser_count <= ser_count + to_unsigned(1,5);  -- Increment count
                        if ser_count = to_unsigned(SER_WIDTH - 2, 5) and curr_proc = "011" then -- For Data Cycle
                            present_substate <= tx_end;
                        elsif ser_count = to_unsigned(CMD_WIDTH - 2, 5) and curr_proc ="001" then -- For CMD Cycle
                            present_substate <= tx_end;
                        else 
                            present_substate <= tx;
                        end if;
                    end if;
                when tx_end => 
                    if spi_clk_rise = '1' then
                        ser_sh_reg <= (others => '1');
                        slsel <= '1';
                        if curr_proc = "001" then
                            data_out_v <= '1';
                            data_out   <= curr_proc & ('0' & (ser_cmd_reg (CMD_WIDTH-2 downto 1) & (ser_data_reg (SER_WIDTH -2 downto 1) & (ser_cmd_reg(0)&("00" & (id))))));
                            if cmd_type_reg = "10" then
                                present_substate <= exist_check;
                                curr_proc <= "010";
                            elsif cmd_type_reg = "01" then
                                present_substate <= busy_check;
                                curr_proc <= "011";
                            else 
                                fifo_deq <= '1';
                                curr_proc <= "000";
                                present_substate <= fifo_deque;
                                if ser_cmd_reg(CMD_WIDTH -2 downto 1) = "00000010" or ser_cmd_reg(CMD_WIDTH -2 downto 1) = "00000101" then
                                    evrm_status <= '0';
                                elsif ser_cmd_reg(CMD_WIDTH -2 downto 1) = "10000101" then
                                    evrm_status <= '1';
                                end if;
                            end if;
                        elsif curr_proc = "011" then
                            fifo_deq <= '1';
                            curr_proc <= "000";
                            present_substate <= fifo_deque;
                            data_out_v <= '1';
                            data_out   <= curr_proc & ('0' & (ser_cmd_reg (CMD_WIDTH-2 downto 1) & (ser_data_reg(SER_WIDTH-2 downto 0) & ("00" & (id)))));
                        end if;
                    else 
                        present_substate <= tx_end;
                    end if;
                when fifo_deque => 
                    fifo_deq   <= '0';
                    data_out_v <= '0';
                    present_substate <= start;
            end case;
        end if;
    end process;

    spi_clk_fall <= '1' when (clk_cnt = to_unsigned(clk_ratio-1,5) and spi_clk = '1') else '0';
	spi_clk_rise <= '1' when (clk_cnt = to_unsigned(clk_ratio-1,5) and spi_clk = '0') else '0';

    clk_div: process (clk, reset)
        
    begin
        if reset = '1' then -- Can be gated.
            clk_cnt <= to_unsigned(0,5);
            spi_clk <= '1';
        elsif falling_edge(clk) then
            if(clk_cnt = to_unsigned(clk_ratio-1,5)) then
                clk_cnt <= to_unsigned(0,5);
                spi_clk <= not spi_clk;
            else
                clk_cnt <= clk_cnt + to_unsigned(1,5);
            end if;
        end if;
    end process;



    sclk <= spi_clk;
	mosi <= ser_sh_reg(SER_WIDTH-1);
    evrm <= evrm_status;

	 --Testing signals
	 --ser_reg <= ser_sh_reg;
	 --lser <= load_ser;
	 --ser_enable <= ser_en;
	 --ser_cnt <= ser_count;
    --cmd_reg <= ser_cmd_reg(8 downto 1);
	 --ser_q <= ser_queue;
end rtl;