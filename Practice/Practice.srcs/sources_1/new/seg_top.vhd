----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 10/26/2026 12:39:56 AM
-- Design Name: 
-- Module Name: seg_top - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity seg_top is
	Port (
		clk : in std_logic;
		pb : in std_logic_vector(4 downto 0);
		segment: out std_logic_vector(6 downto 0);
		common : out std_logic_vector(3 downto 0)
	);
end seg_top;

architecture Behavioral of seg_top is
	signal clk_100hz : std_logic;
	signal clk_1khz : std_logic;
	signal toggle : std_logic;
	type state_t is (S1, S2);
	signal state : state_t := S1;

	signal data : std_logic_vector(6 downto 0);
begin

	u_100hz : entity work.mod500k
		port map (
			clk => clk,
			tick => clk_100hz
		);

	u_1khz : entity work.mod50k
		port map (
			clk => clk,
			tick => clk_1khz
		);

	debounce_center : entity work.debounce
		port map (
			raw => pb(4),
			clk_100hz => clk_100hz,
			debounce => toggle
		);

	display : entity work.display_ascii
		port map (
			d0 => data,
			d1 => data,
			d2 => data,
			d3 => data,
			trigger => clk_1khz,
			clk => clk,
			segment => segment,
			common => common
		);

	data <= std_logic_vector(to_unsigned(69, 7)) when state = S1 else std_logic_vector(to_unsigned(65, 7));

	process(clk_100hz)
	begin
		if rising_edge(clk_100hz) then
			if toggle = '1' then
				if state = S1 then
					state <= S2;
				else
					state <= S1;
				end if;
			end if;
		end if;
	end process;
end Behavioral;
