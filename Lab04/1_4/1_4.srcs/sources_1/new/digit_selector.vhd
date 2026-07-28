----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 07/28/2026 04:02:16 PM
-- Design Name: 
-- Module Name: digit_selector - Behavioral
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

entity digit_selector is
	Port (
		clk : in STD_LOGIC;
		d3 : out STD_LOGIC;
		d2 : out STD_LOGIC;
		d1 : out STD_LOGIC;
		d0 : out STD_LOGIC
	);
end digit_selector;

architecture Behavioral of digit_selector is
	signal count : unsigned(1 downto 0) := "00";
begin
	-- 2-bit counter
	process(clk)
	begin
		if rising_edge(clk) then
			count <= count + 1;
		end if;
	end process;

	d3 <= '1' when count = "11" else '0';
	d2 <= '1' when count = "10" else '0';
	d1 <= '1' when count = "01" else '0';
	d0 <= '1' when count = "00" else '0';
end Behavioral;