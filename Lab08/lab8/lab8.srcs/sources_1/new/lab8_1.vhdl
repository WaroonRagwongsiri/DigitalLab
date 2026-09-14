----------------------------------------------------------------------------
-- lab8_1.vhdl
--
-- Displays "Hello World" on line 1 of a 2x16 character LCD (HD44780-
-- compatible controller), line 2 left blank. 8-bit data bus, R/W tied to
-- GND (write-only), 50 MHz board clock (EDGE Spartan-7).
--
-- Architecture: a ROM of {RS, DATA} entries (init commands + characters),
-- a step counter that walks through the ROM, and an E-pulse FSM that
-- times the setup / enable-pulse / execution-wait around each entry.
----------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity lab8_1 is
    Port ( clk  : in  STD_LOGIC;
           data : out STD_LOGIC_VECTOR(7 downto 0);
           e    : out STD_LOGIC;
           rs   : out STD_LOGIC);
end lab8_1;

architecture Behavioral of lab8_1 is

    -- 50 MHz clock -> 20 ns period
    constant T_POWERUP : integer := 2_000_000; -- 40.0 ms  power-on wait   (datasheet min 15 ms)
    constant T_SETUP   : integer := 10;        -- 0.2 us   RS/data setup before E rises
    constant T_EPULSE  : integer := 50;        -- 1.0 us   E pulse high width (min 450 ns)
    constant T_EXEC    : integer := 100_000;   -- 2.0 ms   instr. execution wait (covers 1.64 ms clear)

    -- ROM entry: bit 8 = RS, bits 7:0 = data byte
    type rom_type is array (0 to 14) of STD_LOGIC_VECTOR(8 downto 0);
    constant lcd_rom : rom_type := (
        0  => '0' & X"38",  -- Function set: 8-bit bus, 2 lines, 5x8 font
        1  => '0' & X"0C",  -- Display ON, cursor off, blink off
        2  => '0' & X"01",  -- Clear display (also homes cursor to line 1, pos 0)
        3  => '0' & X"06",  -- Entry mode set: increment address, no display shift
        4  => '1' & X"48",  -- 'H'
        5  => '1' & X"65",  -- 'e'
        6  => '1' & X"6C",  -- 'l'
        7  => '1' & X"6C",  -- 'l'
        8  => '1' & X"6F",  -- 'o'
        9  => '1' & X"20",  -- ' '
        10 => '1' & X"57",  -- 'W'
        11 => '1' & X"6F",  -- 'o'
        12 => '1' & X"72",  -- 'r'
        13 => '1' & X"6C",  -- 'l'
        14 => '1' & X"64"   -- 'd'
    );

    type state_type is (POWERUP, SETUP, EPULSE, EXEC, DONE);
    signal state   : state_type := POWERUP;
    signal step    : integer range 0 to 14 := 0;
    signal counter : integer range 0 to T_POWERUP := 0;

    signal rs_i   : STD_LOGIC := '0';
    signal data_i : STD_LOGIC_VECTOR(7 downto 0) := (others => '0');
    signal e_i    : STD_LOGIC := '0';

begin

    process(clk)
    begin
        if rising_edge(clk) then
            case state is

                when POWERUP =>
                    e_i <= '0';
                    if counter < T_POWERUP - 1 then
                        counter <= counter + 1;
                    else
                        counter <= 0;
                        rs_i    <= lcd_rom(step)(8);
                        data_i  <= lcd_rom(step)(7 downto 0);
                        state   <= SETUP;
                    end if;

                when SETUP =>  -- RS/data already driven from ROM; hold before E rises
                    if counter < T_SETUP - 1 then
                        counter <= counter + 1;
                    else
                        counter <= 0;
                        e_i     <= '1';
                        state   <= EPULSE;
                    end if;

                when EPULSE =>
                    if counter < T_EPULSE - 1 then
                        counter <= counter + 1;
                    else
                        counter <= 0;
                        e_i     <= '0';
                        state   <= EXEC;
                    end if;

                when EXEC =>
                    if counter < T_EXEC - 1 then
                        counter <= counter + 1;
                    else
                        counter <= 0;
                        if step < 14 then
                            step   <= step + 1;
                            rs_i   <= lcd_rom(step + 1)(8);
                            data_i <= lcd_rom(step + 1)(7 downto 0);
                            state  <= SETUP;
                        else
                            state  <= DONE;
                        end if;
                    end if;

                when DONE =>
                    e_i <= '0';  -- stay here forever; message remains on screen

            end case;
        end if;
    end process;

    rs   <= rs_i;
    data <= data_i;
    e    <= e_i;

end Behavioral;
