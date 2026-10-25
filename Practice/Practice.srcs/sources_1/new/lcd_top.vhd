----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 10/25/2026 09:16:16 PM
-- Design Name: 
-- Module Name: lcd_top - Behavioral
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

entity lcd_top is
	port (
		clk		: in std_logic;
		pb		: in std_logic_vector(4 downto 0);
		data	: out std_logic_vector(7 downto 0);
		e		: out std_logic;
		rs		: out std_logic
	);
end lcd_top;

architecture Behavioral of lcd_top is

	-- text -> ASCII bits, 8 bits per letter.	text("Hi") = x"4869"
	function text(s : string) return std_logic_vector is
		variable r : std_logic_vector(s'length*8 - 1 downto 0);
		variable k : integer := 0; -- letter number, 0 = leftmost
	begin
		for i in s'range loop
			r(r'high - 8*k downto r'high - 8*k - 7) :=
				std_logic_vector(to_unsigned(character'pos(s(i)), 8));
			k := k + 1;
		end loop;
		return r;
	end function;

	-- 4 bits -> '0'..'9', blank if 10-15
	function bcd(n : std_logic_vector(3 downto 0)) return std_logic_vector is
	begin
		if unsigned(n) <= 9 then
			return std_logic_vector(to_unsigned(48 + to_integer(unsigned(n)), 8));
		else
			return x"20";
		end if;
	end function;

	function bit_cd(n : std_logic) return std_logic_vector is
		begin
			if n = '1' then
				return x"31"; -- '1'
			else
				return x"30"; -- '0'
		end if;
	end function;

	function spaces(n : integer) return std_logic_vector is
		variable r : std_logic_vector(n*8 - 1 downto 0);
	begin
		for i in 0 to n - 1 loop
			r(8*i + 7 downto 8*i) := x"20";
		end loop;
		return r;
	end function;

	signal line1, line2 : std_logic_vector(127 downto 0);

	signal clk_100hz : std_logic;

	type state_t is (HELLO, BYE);
	signal state : state_t;
	signal toggle : std_logic;
begin

	u_100hz : entity work.mod500k
		port map (
			clk => clk,
			tick => clk_100hz
		);

	debounce_center : entity work.debounce
		port map (
			raw => pb(4),
			clk_100hz => clk_100hz,
			debounce => toggle
		);

	process (clk_100hz)
	begin
		if rising_edge(clk_100hz) then
			if toggle = '1' then
				if state = HELLO then
					state <= BYE;
				elsif state = BYE then
					state <= HELLO;
				end if;
			end if;
		end if;
	end process;

	line1 <= text("Counter 0 to 9") & spaces(2);
	line2 <= text("HELLO") & spaces(11) when state = HELLO else
			text("BYE") & spaces(13);
	lcd : entity work.LCD_DISPLAY
		port map (
			CLK => clk,
			LINE1 => line1,
			LINE2 => line2,
			LCD_RS => rs,
			LCD_E => e,
			LCD_DATA => data
		);
end Behavioral;
