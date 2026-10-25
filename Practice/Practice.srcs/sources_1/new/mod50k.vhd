library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity mod50k is
	port (
		clk	: in std_logic;
		tick : out std_logic
	);
end mod50k;

architecture rtl of mod50k is
	signal cnt : integer range 0 to 49_999 := 0;
begin
	process(clk)
	begin
		if rising_edge(clk) then
			if cnt = 49_999 then
				cnt <= 0;
				tick <= '1';
			else
				cnt <= cnt + 1;
				tick <= '0';
			end if;
		end if;
	end process;
end rtl;
