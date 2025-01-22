library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity packet_parity is
    Port (
        packet_in : in std_logic_vector(31 downto 0); -- 32-bit input packet
        packet_out : out std_logic_vector(31 downto 0) -- 32-bit output packet
    );
end packet_parity;

architecture Behavioral of packet_parity is

    -- Function to calculate mod-4 parity (2 bits)
    function calculate_mod4_parity(bits : std_logic_vector) return std_logic_vector is
        variable ones_count : integer := 0;
    begin
        for i in bits'range loop
            if bits(i) = '1' then
                ones_count := ones_count + 1;
            end if;
        end loop;
        return std_logic_vector(to_unsigned(ones_count mod 4, 2));
    end function;

begin

    process(packet_in)
        variable parity : std_logic_vector(1 downto 0);
        variable temp_packet : std_logic_vector(31 downto 0);
    begin
        -- Calculate mod-4 parity for all bits except 28 and 2
        parity := calculate_mod4_parity(packet_in(31 downto 29) & packet_in(27 downto 3) & packet_in(1 downto 0));

        -- Replace bits 28 and 2 in the output packet with calculated parity
        temp_packet := packet_in;
        temp_packet(28) := parity(1); -- Upper bit of mod-4 parity
        temp_packet(2) := parity(0);  -- Lower bit of mod-4 parity

        packet_out <= temp_packet;
    end process;

end Behavioral;
