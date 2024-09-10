library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.MATH_REAL.ALL;

entity UART is
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
end entity;

architecture RTL of UART is

    constant OS_CLK_DIV_VAL   : integer := integer(real(CLK_FREQ)/real(16*BAUD_RATE));
    constant UART_CLK_DIV_VAL : integer := integer(real(CLK_FREQ)/real(OS_CLK_DIV_VAL*BAUD_RATE));
    constant STOP_BYTE        : std_logic_vector(7 downto 0) := (others => '1');

    signal os_clk_en            : std_logic;
    signal uart_rxd_meta_n      : std_logic;
    signal uart_rxd_synced_n    : std_logic;
    signal uart_rxd_debounced_n : std_logic;
    signal uart_rxd_debounced   : std_logic;
	 signal din_rdy_sig          : std_logic;

    signal data_buffer          : std_logic_vector(63 downto 0);
    signal byte_counter         : integer range 0 to 8 := 0;
    signal din                  : std_logic_vector(7 downto 0);
    signal din_vld              : std_logic := '0';

begin

    -- UART clock divider and clock enable
    os_clk_divider_i : entity work.UART_CLK_DIV
    generic map(
        DIV_MAX_VAL  => OS_CLK_DIV_VAL,
        DIV_MARK_POS => OS_CLK_DIV_VAL-1
    )
    port map (
        CLK      => CLK,
        RST      => RST,
        CLEAR    => RST,
        ENABLE   => '1',
        DIV_MARK => os_clk_en
    );

    -- UART RXD cross domain crossing
    uart_rxd_cdc_reg_p : process (CLK)
    begin
        if (falling_edge(CLK)) then
            uart_rxd_meta_n   <= not UART_RXD;
            uart_rxd_synced_n <= uart_rxd_meta_n;
        end if;
    end process;

    -- UART RXD debouncer
    use_debouncer_g : if (USE_DEBOUNCER = True) generate
        debouncer_i : entity work.UART_DEBOUNCER
        generic map(
            LATENCY => 4
        )
        port map (
            CLK     => CLK,
            DEB_IN  => uart_rxd_synced_n,
            DEB_OUT => uart_rxd_debounced_n
        );
    end generate;

    not_use_debouncer_g : if (USE_DEBOUNCER = False) generate
        uart_rxd_debounced_n <= uart_rxd_synced_n;
    end generate;

    uart_rxd_debounced <= not uart_rxd_debounced_n;

    -- UART receiver
    uart_rx_i: entity work.UART_RX
    generic map (
        CLK_DIV_VAL => UART_CLK_DIV_VAL,
        PARITY_BIT  => PARITY_BIT
    )
    port map (
        CLK          => CLK,
        RST          => RST,
        -- UART INTERFACE
        UART_CLK_EN  => os_clk_en,
        UART_RXD     => uart_rxd_debounced,
        -- USER DATA OUTPUT INTERFACE
        DOUT         => DOUT,
        DOUT_VLD     => DOUT_VLD,
        FRAME_ERROR  => FRAME_ERROR,
        PARITY_ERROR => PARITY_ERROR
    );

    -- Packetization and transmission logic
    process(CLK)
    begin
        if falling_edge(CLK) then
            if RST = '1' then
                byte_counter <= 0;
                din <= (others => '0');
                din_vld <= '0';
            else
                din_vld <= '0'; -- Default value
                
                if din_rdy_sig = '1' and FIFO_EMPTY = '0' then
                    if byte_counter = 0 then
                        data_buffer <= FIFO_DATA; -- Load the 64-bit packet from FIFO
                    end if;
                    
                    case byte_counter is
                        when 0 =>
                            din <= data_buffer(63 downto 56);
                            din_vld <= '1';
                        when 1 =>
                            din <= data_buffer(55 downto 48);
                            din_vld <= '1';
                        when 2 =>
                            din <= data_buffer(47 downto 40);
                            din_vld <= '1';
                        when 3 =>
                            din <= data_buffer(39 downto 32);
                            din_vld <= '1';
                        when 4 =>
                            din <= data_buffer(31 downto 24);
                            din_vld <= '1';
                        when 5 =>
                            din <= data_buffer(23 downto 16);
                            din_vld <= '1';
                        when 6 =>
                            din <= data_buffer(15 downto 8);
                            din_vld <= '1';
                        when 7 =>
                            din <= data_buffer(7 downto 0);
                            din_vld <= '1';
                        when 8 =>
                            din <= STOP_BYTE; -- Send the stop byte
                            din_vld <= '1';
                    end case;
                    
                    if byte_counter = 8 then
                        byte_counter <= 0; -- Reset counter after sending the stop byte
                    else
                        byte_counter <= byte_counter + 1;
                    end if;
                end if;
            end if;
        end if;
    end process;

    -- UART transmitter
    uart_tx_i: entity work.UART_TX
    generic map (
        CLK_DIV_VAL => UART_CLK_DIV_VAL,
        PARITY_BIT  => PARITY_BIT
    )
    port map (
        CLK         => CLK,
        RST         => RST,
        -- UART INTERFACE
        UART_CLK_EN => os_clk_en,
        UART_TXD    => UART_TXD,
        -- USER DATA INPUT INTERFACE
        DIN         => din,
        DIN_VLD     => din_vld,
        DIN_RDY     => din_rdy_sig
    );
	 
	 DIN_RDY <= din_rdy_sig;

end architecture;

