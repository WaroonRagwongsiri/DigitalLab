----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 07/28/2026 04:01:20 PM
-- Design Name: 
-- Module Name: mod10 - Behavioral
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

entity mod_10 is
	Port (
		clk : in  STD_LOGIC;
		clk_mod10 : out STD_LOGIC
	);
end mod_10;

architecture Behavioral of mod_10 is
	signal count : integer range 0 to 4 := 0;
	signal clk_track : STD_LOGIC := '0';
begin
	process(clk)
	begin
		if rising_edge(clk) then
			if count = 4 then
				count <= 0;
				clk_track <= not clk_track;
			else
				count <= count + 1;
			end if;
		end if;
	end process;
	
	clk_mod10 <= clk_track;
end Behavioral;