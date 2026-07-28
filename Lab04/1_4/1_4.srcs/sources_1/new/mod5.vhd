----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 07/28/2026 04:02:00 PM
-- Design Name: 
-- Module Name: mod5 - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: Mod 5 CLK
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

entity mod_5 is
	Port (
		clk : in  STD_LOGIC;
		clk_mod5 : out STD_LOGIC
	);
end mod_5;

architecture Behavioral of mod_5 is
	signal count : integer range 0 to 4 := 0;
begin
	process(clk)
	begin
		if rising_edge(clk) then
			if count = 4 then
				count <= 0;
			else
				count <= count + 1;
			end if;
		end if;
	end process;
	
	-- Creates a clock-like pulse
	clk_mod5 <= '1' when count < 2 else '0';
end Behavioral;