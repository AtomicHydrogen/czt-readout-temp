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

    constant command_valids : command_array := (
        x"E0", x"E1", x"E2", x"E3", x"E4", x"E5", x"E6", x"E7", x"E8", x"E9",
        x"9D", x"9E", x"86", x"A3", x"96", x"9A", x"02", x"85", x"05", x"8C",
        x"21", x"A1", x"1F", x"9F", x"20", x"A0", x"81", x"01", x"32", x"B2",
        x"34", x"B4", x"07", x"87", x"0B", x"8B", x"84", x"04", x"CB", x"10", 
        x"90", x"48", x"C8"
    );

    constant command_has_reply : command_array := (
        x"E0", x"9D", x"9E", x"86", x"A3", x"96", x"9A", x"A1", x"9F", x"A0",
        x"B2", x"B4", x"87", x"8B", x"C8", x"84", x"CB"
    );

    constant command_has_data : command_array := (
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

    function calculate_parity(bits : std_logic_vector(31 downto 0)) return std_logic_vector is
        variable count : integer := 0;
        variable parity : std_logic_vector(1 downto 0);
    begin
        for i in 0 to 28 loop
            if bits(i) = '1' then
                count := count + 1;
            end if;
        end loop;
        for i in 31 downto 31 loop
            if bits(i) = '1' then
                count := count + 1;
            end if;
        end loop;
        parity := std_logic_vector(to_unsigned(count mod 4, 2));
        return parity;
    end function;

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
        expected_parity := calculate_parity(packet_in);
        if packet_in_v = '1' then
            if actual_parity /= expected_parity then
                validation_bit <= '0'; -- Parity mismatch
            elsif not is_in_array(cmd_id, command_valids) then
                validation_bit <= '0'; -- Invalid command ID
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
