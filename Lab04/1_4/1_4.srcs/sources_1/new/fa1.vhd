----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 07/28/2026 05:31:41 PM
-- Design Name: 
-- Module Name: fa1 - Behavioral
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

entity fa1 is
	Port (
		lhs : in STD_LOGIC;
		rhs : in STD_LOGIC;
		carry_in : in STD_LOGIC;
		carry_out : out STD_LOGIC;
		sum : out STD_LOGIC
	);
end fa1;

architecture Behavioral of fa1 is
	signal n1_o, n2_o, n3_o, n4_o, n5_o : STD_LOGIC;
begin

	-- combinational logic
	n1_o <= lhs xor rhs;
	n2_o <= n1_o xor carry_in;
	n3_o <= lhs and rhs;
	n4_o <= n1_o and carry_in;
	n5_o <= n3_o or n4_o;

	-- output drivers
	carry_out <= n5_o;
	sum <= n2_o;

end Behavioral;
