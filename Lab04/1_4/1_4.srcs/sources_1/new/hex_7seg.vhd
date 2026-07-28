----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 07/27/2026 05:20:07 PM
-- Design Name: 
-- Module Name: hex_7seg - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 7-Segment Display Decoder (Common Anode)
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

entity hex_7seg is
	Port ( 
		sw22 : in STD_LOGIC;
		sw21 : in STD_LOGIC;
		sw19 : in STD_LOGIC;
		sw17 : in STD_LOGIC;
		a : out STD_LOGIC;
		b : out STD_LOGIC;
		c : out STD_LOGIC;
		d : out STD_LOGIC;
		e : out STD_LOGIC;
		f : out STD_LOGIC;
		g : out STD_LOGIC
	);
end hex_7seg;

architecture Behavioral of hex_7seg is
begin
	-- Segment A K-Map
	a <= (not sw22 and not sw21 and not sw19 and sw17) or 
		(not sw22 and sw21 and not sw19 and not sw17) or 
		(sw22 and not sw21 and sw19 and sw17) or 
		(sw22 and sw21 and not sw19 and sw17);

	-- Segment B K-Map
	b <= (not sw22 and sw21 and not sw19 and sw17) or 
		(sw22 and sw21 and not sw17) or 
		(sw22 and sw19 and sw17) or 
		(sw21 and sw19 and not sw17);

	-- Segment C K-Map
	c <= (not sw22 and not sw21 and sw19 and not sw17) or 
		(sw22 and sw21 and sw19) or 
		(sw22 and sw21 and not sw17);

	-- Segment D K-Map
	d <= (not sw22 and not sw21 and not sw19 and sw17) or 
		(not sw22 and sw21 and not sw19 and not sw17) or 
		(sw22 and not sw21 and sw19 and not sw17) or 
		(sw21 and sw19 and sw17);

	-- Segment E K-Map
	e <= (not sw22 and sw21 and not sw19) or 
		(not sw22 and sw17) or 
		(not sw21 and not sw19 and sw17);

	-- Segment F K-Map
	f <= (not sw22 and not sw21 and sw19) or 
		(not sw22 and not sw21 and sw17) or 
		(not sw22 and sw19 and sw17) or 
		(sw22 and sw21 and not sw19 and sw17);

	-- Segment G K-Map
	g <= (not sw22 and not sw21 and not sw19) or 
		(not sw22 and sw21 and sw19 and sw17) or 
		(sw22 and sw21 and not sw19 and not sw17);
end Behavioral;