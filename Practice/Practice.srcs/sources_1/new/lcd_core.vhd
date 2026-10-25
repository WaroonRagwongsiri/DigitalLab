-- ============================================================
-- lcd_core.vhd
-- Sends ONE byte to the LCD, then waits WAIT_US microseconds.
-- Also waits 40 ms after power-up (BUSY = '1' during that time).
--
-- To send a byte: when BUSY = '0', set RS_IN, DATA_IN, WAIT_US
-- and hold START = '1' until BUSY goes '1'.
-- ============================================================
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity LCD_CORE is
	port (
		CLK			: in std_logic; -- 50 MHz
		START		: in std_logic;
		RS_IN		: in std_logic; -- '0' = command, '1' = character
		DATA_IN		: in std_logic_vector(7 downto 0);
		WAIT_US		: in integer range 0 to 10_000; -- wait after the E pulse, in us
		BUSY		: out std_logic;
		LCD_RS		: out std_logic;
		LCD_E		: out std_logic;
		LCD_DATA	: out std_logic_vector(7 downto 0)
	);
end LCD_CORE;

architecture rtl of LCD_CORE is

	constant CLK_PER_US	: integer := 50; -- 50 MHz = 50 clocks per us
	constant T_POWER_ON	: integer := 40_000 * CLK_PER_US; -- 40 ms
	constant T_SETUP	: integer := 1 * CLK_PER_US; -- 1 us, RS/data settle
	constant T_E_HIGH	: integer := 5 * CLK_PER_US; -- 5 us, E pulse

	type state_t is (POWER_ON, IDLE, SETUP, E_HIGH, E_WAIT);
	signal state	: state_t := POWER_ON;
	signal timer	: integer range 0 to T_POWER_ON := 0;
	signal t_wait	: integer range 0 to 10_000 * CLK_PER_US := 0;

	signal rs_r		: std_logic := '0';
	signal data_r	: std_logic_vector(7 downto 0) := (others => '0');
	signal e_r		: std_logic := '0';

begin

	process(CLK)
	begin
		if rising_edge(CLK) then
			case state is

				when POWER_ON => -- wait 40 ms once
					if timer = T_POWER_ON - 1 then
						timer <= 0;
						state <= IDLE;
					else
						timer <= timer + 1;
					end if;

				when IDLE => -- copy the inputs when START comes
					if START = '1' then
						rs_r	 <= RS_IN;
						data_r <= DATA_IN;
						t_wait <= WAIT_US * CLK_PER_US;
						timer	<= 0;
						state	<= SETUP;
					end if;

				when SETUP => -- E low, RS and data settle
					if timer = T_SETUP - 1 then
						timer <= 0;
						e_r	 <= '1';
						state <= E_HIGH;
					else
						timer <= timer + 1;
					end if;

				when E_HIGH => -- E high, falling edge = LCD reads
					if timer = T_E_HIGH - 1 then
						timer <= 0;
						e_r	 <= '0';
						state <= E_WAIT;
					else
						timer <= timer + 1;
					end if;

				when E_WAIT => -- LCD is working, wait
					if timer >= t_wait - 1 then
						timer <= 0;
						state <= IDLE;
					else
						timer <= timer + 1;
					end if;

			end case;
		end if;
	end process;

	BUSY <= '0' when state = IDLE else '1';
	LCD_RS <= rs_r;
	LCD_E <= e_r;
	LCD_DATA <= data_r;

end rtl;