library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity validate_command is
    Port (
        packet_in      : in std_logic_vector(31 downto 0); -- 32-bit input packet
        packet_in_v    : in std_logic;
        validation_bit : out std_logic              -- Output validation bit
    );
end validate_command;

architecture Behavioral of validate_command is

    type command_array is array (natural range <>) of std_logic_vector(7 downto 0);

    constant command_valids : command_array := ( -- Valid command IDs (Hard coded)
        x"E0", x"E1", x"E2", x"E3", x"E4", x"E5", x"E6", x"E7", x"E8", x"E9",
        x"9D", x"9E", x"86", x"A3", x"96", x"9A", x"02", x"85", x"05", x"8C",
        x"21", x"A1", x"1F", x"9F", x"20", x"A0", x"81", x"01", x"32", x"B2",
        x"34", x"B4", x"07", x"87", x"0B", x"8B", x"84", x"04", x"CB", x"10", 
        x"90", x"48", x"C8"
    );

    constant command_has_reply : command_array := ( -- Commands that have Data Read Cycles (Hard coded)
        x"E0", x"9D", x"9E", x"86", x"A3", x"96", x"9A", x"A1", x"9F", x"A0",
        x"B2", x"B4", x"87", x"8B", x"C8", x"84", x"CB"
    );

    constant command_has_data : command_array := ( -- Commands that have Data Write Cycles (Hard coded)
        x"21", x"1F", x"20", x"32", x"07", x"0B", x"48", x"04"
    );

    function is_in_array(val : std_logic_vector(7 downto 0); arr : command_array) return boolean is
    begin
        for i in arr'range loop
            if val = arr(i) then
                return true;
            end if;
        end loop;
        return false;
    end function;

    function even_xor_reduce(vec: std_logic_vector) return std_logic is -- XOR_REDUCE FUNC. for parity bit calc.
    variable xor_result : std_logic := '0'; -- Initialize XOR result
    begin
        -- XOR all even-indexed bits (0, 2, 4, 6)
        for i in 0 to (vec'length - 1) loop
            if i mod 2 = 0 then
                xor_result := xor_result xor vec(i);
            end if;
        end loop;
        return xor_result;

    end function even_xor_reduce;

    function odd_xor_reduce(vec: std_logic_vector) return std_logic is -- XOR_REDUCE FUNC. for parity bit calc.
    variable xor_result : std_logic := '0'; -- Initialize XOR result
    begin
        -- XOR all even-indexed bits (0, 2, 4, 6)
        for i in 0 to (vec'length - 1) loop
            if i mod 2 = 1 then
                xor_result := xor_result xor vec(i);
            end if;
        end loop;
        return xor_result;

    end function odd_xor_reduce;

begin

    process(packet_in, packet_in_v)
        variable cmd_id : std_logic_vector(7 downto 0);
        variable cmd_type : std_logic_vector(1 downto 0);
        variable valid : boolean;
        variable expected_parity : std_logic_vector(1 downto 0);
        variable actual_parity : std_logic_vector(1 downto 0);
    begin
        cmd_id := packet_in(10 downto 3); -- Extract command ID
        cmd_type := packet_in(2 downto 1); -- Extract command type
        actual_parity := packet_in(30 downto 29); -- Extract parity bits
        expected_parity := odd_xor_reduce(packet_in) & even_xor_reduce(packet_in); -- Calculate expected parity
        if packet_in_v = '1' then
            if actual_parity /= expected_parity then
                validation_bit <= '0'; -- Parity mismatch
            -- elsif not is_in_array(cmd_id, command_valids) then
            --  validation_bit <= '0'; -- Invalid command ID
            elsif cmd_type = "11" then
                validation_bit <= '0'; -- Invalid command type
            elsif (cmd_type = "10" and not is_in_array(cmd_id, command_has_reply)) or
                (cmd_type = "01" and not is_in_array(cmd_id, command_has_data)) or
                (cmd_type = "00" and (is_in_array(cmd_id, command_has_reply) or is_in_array(cmd_id, command_has_data))) then
                validation_bit <= '0'; -- Command ID and type mismatch
            else
                validation_bit <= '1'; -- Valid command
            end if;
        else 
            validation_bit <= '0';
        end if;
    end process;

end Behavioral;
