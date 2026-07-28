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
		in1 : in STD_LOGIC;
		in2 : in STD_LOGIC;
		in3 : in STD_LOGIC;
		in4 : in STD_LOGIC;
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
	a <= (not in1 and not in2 and not in3 and in4) or 
		(not in1 and in2 and not in3 and not in4) or 
		(in1 and not in2 and in3 and in4) or 
		(in1 and in2 and not in3 and in4);

	-- Segment B K-Map
	b <= (not in1 and in2 and not in3 and in4) or 
		(in1 and in2 and not in4) or 
		(in1 and in3 and in4) or 
		(in2 and in3 and not in4);

	-- Segment C K-Map
	c <= (not in1 and not in2 and in3 and not in4) or 
		(in1 and in2 and in3) or 
		(in1 and in2 and not in4);

	-- Segment D K-Map
	d <= (not in1 and not in2 and not in3 and in4) or 
		(not in1 and in2 and not in3 and not in4) or 
		(in1 and not in2 and in3 and not in4) or 
		(in2 and in3 and in4);

	-- Segment E K-Map
	e <= (not in1 and in2 and not in3) or 
		(not in1 and in4) or 
		(not in2 and not in3 and in4);

	-- Segment F K-Map
	f <= (not in1 and not in2 and in3) or 
		(not in1 and not in2 and in4) or 
		(not in1 and in3 and in4) or 
		(in1 and in2 and not in3 and in4);

	-- Segment G K-Map
	g <= (not in1 and not in2 and not in3) or 
		(not in1 and in2 and in3 and in4) or 
		(in1 and in2 and not in3 and not in4);
end Behavioral;