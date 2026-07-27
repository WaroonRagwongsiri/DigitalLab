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
	Port ( SW22 : in STD_LOGIC;
		SW21 : in STD_LOGIC;
		SW19 : in STD_LOGIC;
		SW17 : in STD_LOGIC;
		D0 : out STD_LOGIC;
		D1 : out STD_LOGIC;
		D2 : out STD_LOGIC;
		D3 : out STD_LOGIC;
		A : out STD_LOGIC;
		B : out STD_LOGIC;
		C : out STD_LOGIC;
		D : out STD_LOGIC;
		E : out STD_LOGIC;
		F : out STD_LOGIC;
		G : out STD_LOGIC;
		DP : out STD_LOGIC);
end hex_7seg;

architecture Behavioral of hex_7seg is

	-- Internal signals to represent the input bits D3-D0
	signal inD3 : STD_LOGIC; 
	signal inD2 : STD_LOGIC; 
	signal inD1 : STD_LOGIC; 
	signal inD0 : STD_LOGIC; 

begin

	-- Map hardware switches to K-map input variables
	inD3 <= SW22; -- MSB
	inD2 <= SW21; 
	inD1 <= SW19; 
	inD0 <= SW17; -- LSB

	-- Segment A K-Map: A'B'C'D + A'BC'D' + AB'CD + ABC'D
	A <= (not inD3 and not inD2 and not inD1 and inD0) or 
			(not inD3 and inD2 and not inD1 and not inD0) or 
			(inD3 and not inD2 and inD1 and inD0) or 
			(inD3 and inD2 and not inD1 and inD0);

	-- Segment B K-Map: A'BC'D + ABD' + ACD + BCD'
	B <= (not inD3 and inD2 and not inD1 and inD0) or 
			(inD3 and inD2 and not inD0) or 
			(inD3 and inD1 and inD0) or 
			(inD2 and inD1 and not inD0);

	-- Segment C K-Map: A'B'CD' + ABC + ABD'
	C <= (not inD3 and not inD2 and inD1 and not inD0) or 
			(inD3 and inD2 and inD1) or 
			(inD3 and inD2 and not inD0);

	-- Segment D K-Map: A'B'C'D + A'BC'D' + AB'CD' + BCD
	D <= (not inD3 and not inD2 and not inD1 and inD0) or 
			(not inD3 and inD2 and not inD1 and not inD0) or 
			(inD3 and not inD2 and inD1 and not inD0) or 
			(inD2 and inD1 and inD0);

	-- Segment E K-Map: A'BC' + A'D + B'C'D
	E <= (not inD3 and inD2 and not inD1) or 
			(not inD3 and inD0) or 
			(not inD2 and not inD1 and inD0);

	-- Segment F K-Map: A'B'C + A'B'D + A'CD + ABC'D
	F <= (not inD3 and not inD2 and inD1) or 
			(not inD3 and not inD2 and inD0) or 
			(not inD3 and inD1 and inD0) or 
			(inD3 and inD2 and not inD1 and inD0);

	-- Segment G K-Map: A'B'C' + A'BCD + ABC'D'
	G <= (not inD3 and not inD2 and not inD1) or 
			(not inD3 and inD2 and inD1 and inD0) or 
			(inD3 and inD2 and not inD1 and not inD0);

	-- Enable all 4 digits by driving the anodes low (Active-Low)
	D0 <= '1';
	D1 <= '1';
	D2 <= '1';
	D3 <= '1';

	-- Turn off Decimal Point (Active-Low -> '1' is OFF)
	DP <= '1';

end Behavioral;