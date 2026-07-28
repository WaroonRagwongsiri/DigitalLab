----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 07/28/2026 04:02:46 PM
-- Design Name: 
-- Module Name: top - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: Testing multiplexing by routing anodes to hex decoder
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity top is
	Port (
		clk : in  STD_LOGIC;
		sw22 : in  STD_LOGIC;
		sw21 : in  STD_LOGIC;
		sw19 : in  STD_LOGIC;
		sw17 : in  STD_LOGIC;
		d0 : out STD_LOGIC;
		d1 : out STD_LOGIC;
		d2 : out STD_LOGIC;
		d3 : out STD_LOGIC;
		a : out STD_LOGIC;
		b : out STD_LOGIC;
		c : out STD_LOGIC;
		d : out STD_LOGIC;
		e : out STD_LOGIC;
		f : out STD_LOGIC;
		g : out STD_LOGIC
	);
end top;

architecture Behavioral of top is
	component mod_5 Port ( clk : in STD_LOGIC; clk_mod5 : out STD_LOGIC ); end component;
	component mod_10 Port ( clk : in STD_LOGIC; clk_mod10 : out STD_LOGIC ); end component;
	component digit_selector Port ( clk : in STD_LOGIC; d3 : out STD_LOGIC; d2 : out STD_LOGIC; d1 : out STD_LOGIC; d0 : out STD_LOGIC ); end component;
	component hex_7seg Port ( sw22 : in STD_LOGIC; sw21 : in STD_LOGIC; sw19 : in STD_LOGIC; sw17 : in STD_LOGIC; a, b, c, d, e, f, g : out STD_LOGIC ); end component;

	signal n1_clk, n2_clk, n3_clk, n4_clk, n5_clk : STD_LOGIC;

	signal sig_d3, sig_d2, sig_d1, sig_d0 : STD_LOGIC;
begin

	u_0 : mod_5 port map ( clk => clk, clk_mod5 => n1_clk );
	u_1 : mod_10 port map ( clk => n1_clk, clk_mod10 => n2_clk );
	u_2 : mod_10 port map ( clk => n2_clk, clk_mod10 => n3_clk );
	u_3 : mod_10 port map ( clk => n3_clk, clk_mod10 => n4_clk );
	u_4 : mod_10 port map ( clk => n4_clk, clk_mod10 => n5_clk );

	u_5 : digit_selector port map (
		clk => n5_clk,
		d3 => sig_d3, 
		d2 => sig_d2, 
		d1 => sig_d1, 
		d0 => sig_d0
	);

	d3 <= sig_d3;
	d2 <= sig_d2;
	d1 <= sig_d1;
	d0 <= sig_d0;

	u_6 : hex_7seg port map (
		sw22 => sig_d3, 
		sw21 => sig_d2, 
		sw19 => sig_d1, 
		sw17 => sig_d0,
		a => a, b => b, c => c, d => d, e => e, f => f, g => g
	);
end Behavioral;