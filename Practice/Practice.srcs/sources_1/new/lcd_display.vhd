-- ============================================================
-- lcd_display.vhd
-- Shows two lines of 16 characters. Init once, then re-sends
-- both lines forever, so the screen follows LINE1 / LINE2.
--
-- A line is 16 characters x 8 bits = 128 bits.
-- The LEFTMOST character is in the top bits (127 downto 120).
-- ============================================================
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity LCD_DISPLAY is
	port (
		CLK			: in std_logic; -- 50 MHz
		LINE1		: in std_logic_vector(127 downto 0);
		LINE2		: in std_logic_vector(127 downto 0);
		LCD_RS		: out std_logic;
		LCD_E		: out std_logic;
		LCD_DATA	: out std_logic_vector(7 downto 0)
	);
end LCD_DISPLAY;

architecture rtl of LCD_DISPLAY is

	constant CMD : std_logic := '0'; -- RS for a command
	constant CHR : std_logic := '1'; -- RS for a character

	-- wait after each byte, in microseconds
	constant T_SHORT : integer := 100;	 -- normal command / character (needs 37 us)
	constant T_CLEAR : integer := 2000;	-- clear screen (needs 1.52 ms)
	constant T_INIT1 : integer := 5000;	-- after first 0x30 (needs 4.1 ms)
	constant T_INIT2 : integer := 200;	 -- after second/third 0x30 (needs 100 us)

	type state_t is (
		INIT1,
		INIT2,
		INIT3,
		FUNC_SET,
		DISP_OFF,
		CLEAR,
		ENTRY_MODE,
		DISP_ON,
		GOTO_LINE1,
		WRITE_LINE1,
		GOTO_LINE2,
		WRITE_LINE2
	);
	signal state	: state_t := INIT1;
	signal idx		: integer range 0 to 15 := 0; -- which character of the line

	-- wires to the core
	signal start	: std_logic := '0';
	signal busy		: std_logic;
	signal rs_in	: std_logic := '0';
	signal data_in	: std_logic_vector(7 downto 0) := (others => '0');
	signal wait_us	: integer range 0 to 10_000 := 0;

begin

	core : entity work.LCD_CORE
		port map (
			CLK => CLK,
			START => start,
			RS_IN => rs_in,
			DATA_IN => data_in,
			WAIT_US => wait_us,
			BUSY => busy,
			LCD_RS => LCD_RS,
			LCD_E => LCD_E,
			LCD_DATA => LCD_DATA
		);

	process(CLK)
		-- load one byte for the core and raise START
		procedure send(rs : std_logic; byte : std_logic_vector(7 downto 0); us : integer) is
		begin
			rs_in	 <= rs;
			data_in <= byte;
			wait_us <= us;
			start	 <= '1';
		end procedure;
	begin
		if rising_edge(CLK) then

			if start = '1' then
				if busy = '1' then -- core took the byte, drop START
					start <= '0';
				end if;

			elsif busy = '0' then -- core is free, send the next byte
				case state is
					-- init (runs once)
					when INIT1		=> send(CMD, x"30", T_INIT1);	state <= INIT2;
					when INIT2		=> send(CMD, x"30", T_INIT2);	state <= INIT3;
					when INIT3		=> send(CMD, x"30", T_INIT2);	state <= FUNC_SET;
					when FUNC_SET	=> send(CMD, x"38", T_SHORT);	state <= DISP_OFF; -- 8-bit, 2 lines
					when DISP_OFF	=> send(CMD, x"08", T_SHORT);	state <= CLEAR;
					when CLEAR		=> send(CMD, x"01", T_CLEAR);	state <= ENTRY_MODE;
					when ENTRY_MODE	=> send(CMD, x"06", T_SHORT);	state <= DISP_ON; -- cursor moves right
					when DISP_ON	=> send(CMD, x"0C", T_SHORT);	state <= GOTO_LINE1; -- on, no cursor

					-- refresh loop (runs forever)
					when GOTO_LINE1 =>
						send(CMD, x"80", T_SHORT);
						idx	 <= 0;
						state <= WRITE_LINE1;

					when WRITE_LINE1 =>
						send(CHR, LINE1(127 - 8*idx downto 120 - 8*idx), T_SHORT);
						if idx = 15 then state <= GOTO_LINE2; else idx <= idx + 1; end if;

					when GOTO_LINE2 =>
						send(CMD, x"C0", T_SHORT);
						idx	 <= 0;
						state <= WRITE_LINE2;

					when WRITE_LINE2 =>
						send(CHR, LINE2(127 - 8*idx downto 120 - 8*idx), T_SHORT);
						if idx = 15 then state <= GOTO_LINE1; else idx <= idx + 1; end if;
				end case;
			end if;

		end if;
	end process;

end rtl;