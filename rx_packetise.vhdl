library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity rx_packetise is 
	Port (
		CLK   : in STD_LOGIC;
		RST   : in STD_LOGIC;
		DIN_V : in STD_LOGIC;
		DIN   : in STD_LOGIC_VECTOR (7 downto 0);
		DOUT  : out STD_LOGIC_VECTOR (31 downto 0);
		DOUT_V: out STD_LOGIC
		
	);
end entity;

architecture rtl of rx_packetise is 
	signal counter : UNSIGNED (2 downto 0) := to_unsigned(0, 3);
	signal buff    : STD_LOGIC_VECTOR(31 downto 0);
begin
	packet_p : process (clk, rst) begin
	 if RST = '1' then
		counter <= to_unsigned(0, 3);
		DOUT    <= (others => '0');
		DOUT_V  <= '0';
		buff    <= (others => '0');
	 elsif (falling_edge(clk)) then
		if DIN_V = '1' then
			if counter = to_unsigned(4, 3) then
				if DIN = "11111111" then
					DOUT_V  <= '1';
					DOUT    <= buff;
					counter <= to_unsigned(0, 3);
					buff    <= (others => '0');
				else 
					DOUT_V  <= '0';
					counter <= to_unsigned(0, 3);
					buff    <= (others => '0');
				end if;
			else 
				counter           <= counter + to_unsigned(1, 3);
				buff( 7 downto 0)  <= DIN;
				buff(31 downto 8)  <= buff (23 downto 0);
			end if;
		end if;
	 end if;
	 end process;

end architecture;