library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tx_packetise is
    port (
        clk          : in  std_logic;
        reset        : in  std_logic;             
        data_in_v    : in  std_logic;              -- Input valid signal
        data_in      : in  std_logic_vector(63 downto 0); -- 64-bit input data
        in_ready     : out std_logic;              -- Input ready signal

        data_out_v   : out std_logic;              -- Output valid signal
        data_out     : out std_logic_vector(31 downto 0); -- 32-bit output data
        out_ready    : in  std_logic               -- Output ready signal
    );
end entity;

architecture Behavioral of tx_packetise is
    type state_type is (IDLE, SEND_FIRST, SEND_SECOND, RELOAD);  -- State enumeration
    signal state : state_type;
    
    signal first_packet  : std_logic_vector(31 downto 0); -- First 32 bits
    signal second_packet : std_logic_vector(31 downto 0); -- Second 32 bits
    signal out_data_reg  : std_logic_vector(31 downto 0); -- Output data register

    signal out_valid_reg : std_logic;                    -- Output valid signal
    signal in_ready_reg  : std_logic;                    -- Input ready signal

begin

    -- Sequential process for state transition and output logic
    process (clk, reset)
    begin
        if reset = '1' then
            state <= IDLE;
            out_valid_reg <= '0';
            in_ready_reg <= '1';    -- Initially ready to receive
        elsif falling_edge(clk) then

            -- Output the data based on the current state
            case state is
                when IDLE => 

                    out_valid_reg <= '0';
                    out_data_reg  <= (others => '0');

                    if(in_ready_reg = '1' and data_in_v = '1') then

                        in_ready_reg  <= '0';

                        first_packet  <= data_in(31 downto  0);
                        second_packet <= data_in(63 downto 32);

                        state <= SEND_FIRST;

                    elsif(in_ready_reg = '0' and data_in_v = '1') then

                        in_ready_reg  <= '1';

                        first_packet  <= data_in(31 downto  0);
                        second_packet <= data_in(63 downto 32);

                        state <= SEND_FIRST;

                    elsif(in_ready_reg = '1' and data_in_v = '0') then
                        in_ready_reg  <= '1';
                        
                        state <= IDLE;

                    elsif(in_ready_reg = '0' and data_in_v = '0') then

                        in_ready_reg  <= '1';

                        state <= IDLE;

                    end if;

                when SEND_FIRST =>

                    in_ready_reg <= '0';

                    if(out_ready = '1') then

                        out_valid_reg <= '1';
                        out_data_reg  <= first_packet; 

                        state <= RELOAD;
                    
                    else 

                        out_valid_reg <= '1';
                        out_data_reg  <= first_packet;

                        state <= SEND_FIRST;

                    end if;

                when RELOAD =>
                
                    in_ready_reg <= '0';

                    out_valid_reg <= '0';
                    
                    state <= SEND_SECOND;

                when SEND_SECOND =>

                    in_ready_reg <= '0';

                    if(out_ready = '1') then

                        out_valid_reg <= '1';
                        out_data_reg  <= second_packet; 

                        state <= IDLE;
                    
                    else 

                        out_valid_reg <= '1';
                        out_data_reg  <= second_packet;

                        state <= SEND_SECOND;

                    end if;

            end case;

        end if;
        
    end process;

    -- Output assignments
    in_ready <= in_ready_reg;
    data_out_v <= out_valid_reg;
    data_out <= out_data_reg;

end architecture;
