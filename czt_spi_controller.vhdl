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
--    Rev1, Aug 27th, 2024
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
entity czt_spi_controller is

    generic (
        SER_WIDTH : NATURAL := 17;   -- Serialiser Register Width
        DES_WIDTH : NATURAL := 25;   -- Deserialiser Register Width
        OUT_WIDTH : NATURAL := 32;   -- Intermediate Output Frame Size
        CMD_WIDTH : NATURAL := 9;    -- Detector Command Length
        DAT_WIDTH : NATURAL := 17;   -- Detector Command associated Data Length
        EVF_WIDTH : NATURAL := 24   -- Event Frame Width
    );
    port (
        clk        : in  STD_LOGIC;                      -- Clock input: 100 MHz
        reset      : in  STD_LOGIC;                      -- Reset input
        wdog_hang  : in  STD_LOGIC;                      -- Highest Level Watchdog input to detect sensor hangs
        cmd        : in  STD_LOGIC_VECTOR(CMD_WIDTH -1 downto 0);   -- Input Command
        cmd_data   : in  STD_LOGIC_VECTOR(DAT_WIDTH -1 downto 0);   -- Data (if) associated with command
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
        data_out   : out STD_LOGIC_VECTOR(OUT_WIDTH -1 downto 0)   -- Output vector, 
                                                         -- Event format: Parity Check Status[24], ChannelX[23:20], ChannelY[19:16], Data[15:4], Res[3:0]
                                                         -- Output Frame: Frame Type[31:28], Parity Status[27], 
    );
end czt_spi_controller;

-- Architecture body
architecture rtl of czt_spi_controller is
    --States Enum defintion
    type c_state is (start, rx, tx, exist_check, exist_check_fail, busy_check, busy_check_fail, rx_init, tx_init, rx_end, tx_end);


    signal curr_proc : STD_LOGIC_VECTOR (2 downto 0) := "000"; -- Describes the overall state of the SPI Controller
    --CURR PROC:
    --000 :             IDLE
    --001 :        CMD CYCLE
    --010 :  DATA READ CYCLE
    --011 : DATA WRITE CYCLE
    --100 : EVENT READ CYCLE
    --101 :      FORCE BREAK
    --110 :    FORCE EVRM ON
    --111 :   FORCE EVRM OFF

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

    signal ser_cmd_reg    : STD_LOGIC_VECTOR(CMD_WIDTH -1 downto 0); -- Command TX Packet Holding Register
    signal ser_data_reg   : STD_LOGIC_VECTOR (SER_WIDTH -1 downto 0); --    Data TX Packet Holding Register
    signal cmd_type_reg   : STD_LOGIC_VECTOR (1 downto 0);              -- Command Type Holding Register

    signal wdog_warning   : STD_LOGIC := '0'; -- Active High if detector hang watchdog ever gets triggered

    signal clk_cnt        : UNSIGNED (4 downto 0) := to_unsigned(0, 5); -- CLK Divider

    signal spi_clk        : STD_LOGIC; -- SCLK
    signal spi_clk_rise   : STD_LOGIC := '0'; -- Determine SCLK rising edges - written for a falling edge trig'd main circuit
    signal spi_clk_fall   : STD_LOGIC := '0'; -- Determine SCLK falling edges - also written for a falling edge trig'd main circuit

    signal evrm_status    : STD_LOGIC := '0'; -- Sensor EVRM state according to the SPI Controller (1 for ON, 0 for OFF)

    constant clk_ratio    : INTEGER range 5 to 25  := 5; -- SCLK RATIO: CURRENTLY 5 => 10 MHz SPI
                                                          -- clk_ratio = f_board/(2 x f_spi)

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
            mosi             <= '1';            -- Have taken MOSI = '1' when not in use
            slsel            <= '1';            
            trig             <= '1';
            data_out_v       <= '0';
            data_out         <= (others => '0');

        elsif falling_edge(clk) then
            case present_substate is
                when start => 
                    -- Static Signals Start
                    fifo_deq         <= '0';
                    present_substate <= start;
                    ser_queue        <= (others => '0');
                    ser_cmd_reg      <= (others => '0');
                    ser_data_reg     <= (others => '0');
                    mosi             <= '1';
                    slsel            <= '1';
                    trig             <= '1';
                    data_out_v       <= '0';
                    data_out         <= (others => '0');
                    -- Static Signals End
                    if cmd_hp = '1' then
                        if evrm_status = '0' then -- HP COMMAND AND NOT IN EVRM, LOAD COMMAND
                            present_substate <= busy_check;
                            ser_cmd_reg  <= cmd(23 downto 16) & xor_reduce(cmd(23 downto 16));
                            ser_data_reg <= cmd(15 downto  0) & xor_reduce(cmd(15 downto  0));
                            cmd_type_reg <= cmd_type;
                            curr_proc <= "001";
                        else 
                            present_substate <= busy_check; -- HP COMMAND AND IN EVRM, FORCE EVRM OFF
                            ser_cmd_reg  <= "00000101" & xor_reduce("00000101");
                            ser_data_reg <= (others => '0');
                            cmd_type_reg <= "00";
                            curr_proc <= "111";
                            evrm_status <= '0';
                        end if;
                    else
                        if evrm_status = '1' then -- NO HP COMMAND AND IN EVRM, CHECK FOR EVENTS
                            present_substate <= exist_check;
                            curr_proc <= "000";
                        elsif cmd_ready = '0' then  -- NO COMMAND OF ANY PRIORITY AND NOT IN EVRM, FORCE EVRM ON
                            present_substate <= busy_check;
                            ser_cmd_reg  <= "10000101" & xor_reduce("10000101");
                            ser_data_reg <= (others => '0');
                            cmd_type_reg <= "00";
                            curr_proc <= "110";
                            evrm_status <= '1';
                        else -- COMMAND OF NORMAL PRIORITY AND NOT IN EVRM, LOAD COMMAND
                            present_substate <= busy_check;
                            ser_cmd_reg  <= cmd(23 downto 16) & xor_reduce(cmd(23 downto 16));
                            ser_data_reg <= cmd(15 downto  0) & xor_reduce(cmd(15 downto  0));
                            cmd_type_reg <= cmd_type;
                            curr_proc <= "001";
                        end if;
                    end if;
                when exist_check =>
                    if spi_clk_rise = '1' then
                        slsel <= '0'; -- Push SS LOW at SPI_CLK rising edge, to start the process of checking
                        present_substate <= rx_init;

                    end if;
                when rx_init =>
                    if spi_clk_fall = '1' then
                        if miso = '0' then -- If the Detector has an event/Is ready for Data Readout, start RX
                            present_substate <= rx;
                            if curr_proc = "000" then
                                curr_proc <= "100"; -- Move from Idle to Event Readout mode
                            end if;
                        else 
                            present_substate <= exist_check_fail; -- Deal with failure :'(
                        end if;
                    end if;
                when exist_check_fail => -- Coping with failure and rejection :'(
                    if spi_clk_rise = '1' then -- Only pull SS HIGH at a rising edge of SPI_CLK
                        if curr_proc = "000" then -- If originaly in Idle, try to get a CMD sent since no events in detector
                            slsel <= '1';
                            if cmd_ready = '1' then -- NO EVENTS AND COMMAND WAITING, LOAD COMMAND
                                present_substate <= busy_check;
                                ser_cmd_reg  <= "00000101" & xor_reduce("00000101");
                                ser_data_reg <= (others => '0');
                                cmd_type_reg <= "00";
                                curr_proc <= "111";
                                evrm_status <= '0';
                            else -- NO EVENT AND NO COMMAND WAITING, RETURN TO START
                                present_substate <= start;
                                curr_proc <= "000";
                            end if;
                        else 
                            if wdog_warning = '1' then -- Something is wrong with the detector, reset it with Force Break
                                wdog_warning <= '0';
                                present_substate <= busy_check;
                                ser_cmd_reg  <= "00000010" & xor_reduce("00000010"); -- 02H
                                ser_data_reg <= (others => '0');
                                cmd_type_reg <= "00";
                                curr_proc <= "101";
                                evrm_status <= '0';
                            else 
                                present_substate <= exist_check; -- Otherwise retry
                            end if;
                        end if;
                    else
                        present_substate <= exist_check_fail;
                    end if;
                        
                when rx =>
                    if spi_clk_fall = '1' then
                        if des_count = to_unsigned(DES_WIDTH, 5) and curr_proc = "100" then -- If we expect a Data Read
                            present_substate <= rx_end;
                            data_out_v <= '1';
                            data_out   <= curr_proc & ('1' & (ser_cmd_reg &(des_sh_reg &("000")))); -- Event Readout
                        elsif des_count = to_unsigned(DAT_WIDTH, 5) and curr_proc = "010" then -- If we expect an Event Read
                            fifo_deq <= '1';
                            present_substate <= rx_end;
                            data_out_v <= '1';
                            data_out   <= curr_proc & ('1' & (ser_cmd_reg &(des_sh_reg &("000")))); -- Data Readout
                        else present_substate <= rx;
                        end if;
                    else
                        present_substate <= rx;
                    end if;
                when rx_end =>
                    fifo_deq <= '0';
                    data_out_v <= '0';
                    data_out <= (others => '0');
                    if spi_clk_rise = '1' then
                        present_substate <= start; -- Triggering logic needs to be put here and in rx_init
                        slsel <= '1';
                    else 
                        present_substate <= rx_end;
                    end if;
                when busy_check =>
                    if spi_clk_rise = '1' then
                        slsel <= '0'; -- Push SS LOW on SPI_CLK rising edges only
                        present_substate <= tx_init;
                        if curr_proc = "001" then
                            mosi <= '0'; -- Acc. to Detector Spec, 0 for CMD/COMM cycles
                        else 
                            mosi <= '1'; -- Acc. to Detector Spec, 1 for Data Write cycles
                        end if;
                    else 
                        present_substate <= busy_check;
                    end if;
                when busy_check_fail =>
                    if spi_clk_rise = '1' then
                        slsel <= '1';
                        if wdog_warning = '1' then -- DETECTOR IS STUCK, FORCE CLEAR
                            wdog_warning <= '0';
                            present_substate <= busy_check;
                            ser_cmd_reg  <= "00000010" & xor_reduce("00000010"); -- 02H
                            ser_data_reg <= (others => '0');
                            cmd_type_reg <= "00";
                            curr_proc <= "101";
                            evrm_status <= '0';
                        else
                            present_substate <= busy_check;
                        end if;
                    else 
                        present_substate <= busy_check_fail;
                    end if;
                            
            
                when tx_init =>
                    if spi_clk_fall = '1' then
                        if miso = '0' then 
                            if curr_proc = "001" then
                                ser_queue <= ser_cmd_reg; -- Load CMD
                            else 
                                ser_queue <= ser_data_reg; -- Load Data
                            end if;
                            present_substate <= tx;
                        else 
                            present_substate <= busy_check_fail;
                        end if;
                    end if;
                
                when tx => -- Same Logic as RX
                    if spi_clk_rise = '1' then
                        mosi <= ser_out;
                    end if;
                    if ser_count = to_unsigned(SER_WIDTH, 5) and curr_proc = "011" then -- For Data Cycle
                        present_substate <= tx_end;
                        data_out_v <= '1';
                        data_out   <= curr_proc & ('0' & (ser_cmd_reg (CMD_WIDTH-1 downto 1) & (ser_data_reg & ("000"))));
                    elsif ser_count = to_unsigned(CMD_WIDTH, 5) and (curr_proc ="001" or curr_proc = "101" or curr_proc = "110" or curr_proc = "111") then -- For CMD Cycle
                        present_substate <= tx_end;
                        data_out_v <= '1';
                        data_out   <= curr_proc & ('0' & (ser_cmd_reg (CMD_WIDTH-1 downto 1) & (ser_data_reg (SER_WIDTH -1 downto 0) & (ser_cmd_reg(0)&("000")))));
                    else 
                        present_substate <= tx;
                    end if;
                when tx_end => 
                    data_out_v <= '0';
                    data_out   <= (others => '0');
                    if spi_clk_rise = '1' then
                        mosi  <= '1';
                        slsel <= '1';
                        if curr_proc = "001" then
                            if cmd_type = "10" then
                                present_substate <= exist_check;
                                curr_proc <= "010";
                            elsif cmd_type = "01" then
                                present_substate <= busy_check;
                                curr_proc <= "011";
                            else 
                                fifo_deq <= '1';
                                curr_proc <= "000";
                                present_substate <= start;
                            end if;
                        elsif curr_proc = "101" or curr_proc = "110" or curr_proc = "111" then
                            curr_proc <= "000";
                            present_substate <= start;
                        else 
                            fifo_deq <= '1';
                            curr_proc <= "000";
                            present_substate <= start;
                        end if;
                    else 
                        present_substate <= tx_end;
                    end if;
                    
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

    des_en <= '1' when (spi_clk_fall = '1' and present_substate = rx) else '0';
    des_reg: process (clk, reset) is
        begin
            if reset = '1' then
                des_sh_reg <= (others => '0');
                des_count <= (others => '0');
            elsif falling_edge(clk) then 
                if des_en = '1' then
                    if des_count = to_unsigned(DES_WIDTH, 5) and curr_proc = "100" then
                        des_count <= (others => '0');
                        des_sh_reg <= (others => '0');
                    elsif des_count = to_unsigned(DAT_WIDTH, 5) and curr_proc = "010" then
                        des_count <= (others => '0');
                        des_sh_reg <= (others => '0');
                    else 
                        des_sh_reg(25 downto 1) <= des_sh_reg(24 downto 0); -- Shift
                        des_sh_reg(0)                 <= miso;              -- Clock MISO into the register
                        des_count <= des_count + to_unsigned(1, 5);
                    end if;
                end if;
            end if;
        end process;

    load_ser <= '1' when (spi_clk_fall = '1' and miso = '0' and present_substate = tx_init);
    ser_en   <= '1' when(load_ser = '1' or (spi_clk_rise = '1' and present_substate = tx));
    ser_reg: process(clk, reset)
        begin
            if reset = '1' then
                ser_sh_reg <= (others => '0');
                ser_count <= to_unsigned(0, 5);
                ser_out <= '0';
            elsif falling_edge(clk) then --wrong
                if ser_en = '1' then
                    if ser_count = to_unsigned(0, 5) then
                        if load_ser = '1' then
                            ser_sh_reg <= ser_queue;  -- Load parallel data into shift register
                            ser_count <= to_unsigned(0, 5);  -- Reset serialiser count
                        else 
                            ser_sh_reg <= (others => '0'); -- Reset the register in case no action is required
                            ser_count <= to_unsigned(0,5);  -- Increment count
                        end if;
                    elsif ser_count = to_unsigned(SER_WIDTH, 5) and curr_proc = "011" then
                        ser_count <= to_unsigned(0,5);
                        ser_sh_reg <= (others => '0');
                    elsif ser_count = to_unsigned(CMD_WIDTH, 5) and (curr_proc ="001" or curr_proc = "101" or curr_proc = "110" or curr_proc = "111") then
                        ser_count <= to_unsigned(0,5);
                        ser_sh_reg <= (others => '0');
                    else
                        ser_sh_reg <= ser_sh_reg(SER_WIDTH-2 downto 0) & '0';  -- Shift left
                        ser_count <= ser_count + to_unsigned(1,5);  -- Increment count
                    end if;
                    ser_out <= ser_sh_reg(SER_WIDTH-1);  -- Output the MSB
                    
                    
                end if;
            end if;
        end process;
    
    wdog_detect: process (clk, reset)
    begin
        if reset = '1' then
            wdog_warning <= '0';
        elsif falling_edge(clk) then
            if wdog_hang = '0' and wdog_warning = '0' then
                wdog_warning <= '1';
            end if;
        end if;
    end process;
end rtl;