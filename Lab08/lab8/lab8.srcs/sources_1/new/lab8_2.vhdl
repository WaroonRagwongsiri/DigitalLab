----------------------------------------------------------------------------
-- lab8_2.vhdl
--
-- Line 1: student ID "68011008" (fixed, written once).
-- Line 2: 4-digit BCD value read from the 16 slide switches (sw[15:0]),
--         split into four 4-bit nibbles. Per the XDC's own pin comments
--         (sw[15] = MSB, sw[0] = LSB), the MSB nibble (sw[15:12]) is
--         shown leftmost and the LSB nibble (sw[3:0]) rightmost. Any
--         nibble > 9 (not valid BCD) is shown as a blank space instead
--         of a digit. Line 2 is continuously re-sent (~every 10 ms) so
--         it tracks the switches live.
--
-- 8-bit LCD data bus, R/W tied to GND (write-only), 50 MHz board clock
-- (EDGE Spartan-7).
----------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity lab8_2 is
    Port ( clk  : in  STD_LOGIC;
           sw   : in  STD_LOGIC_VECTOR(15 downto 0);
           data : out STD_LOGIC_VECTOR(7 downto 0);
           e    : out STD_LOGIC;
           rs   : out STD_LOGIC);
end lab8_2;

architecture Behavioral of lab8_2 is

    -- 50 MHz clock -> 20 ns period
    constant T_POWERUP : integer := 2_000_000; -- 40.0 ms  power-on wait
    constant T_SETUP   : integer := 10;        -- 0.2 us   RS/data setup before E rises
    constant T_EPULSE  : integer := 50;        -- 1.0 us   E pulse high width
    constant T_EXEC    : integer := 100_000;   -- 2.0 ms   instruction execution wait

    constant LAST_INIT_STEP : integer := 12;   -- "set DDRAM address -> line 2" step
    constant LAST_STEP      : integer := 16;   -- last of the 4 digit-write steps

    -- RS bit for a given step: '0' for the 5 command steps (0-3 and 12),
    -- '1' for every character-data step. A scalar return, so there's no
    -- array-slice direction to worry about.
    function step_rs(step_idx : integer) return STD_LOGIC is
    begin
        case step_idx is
            when 0 | 1 | 2 | 3 | 12 => return '0';
            when others             => return '1';
        end case;
    end function;

    -- Converts one 4-bit switch nibble to the character to display:
    -- '0'-'9' for valid BCD (0-9), blank space for anything > 9. Both
    -- branches go through to_unsigned/std_logic_vector so the returned
    -- index direction is always the same, regardless of which branch runs.
    function bcd_char(nib : STD_LOGIC_VECTOR(3 downto 0)) return STD_LOGIC_VECTOR is
    begin
        if unsigned(nib) <= 9 then
            return std_logic_vector(to_unsigned(48 + to_integer(unsigned(nib)), 8)); -- '0'-'9'
        else
            return std_logic_vector(to_unsigned(32, 8)); -- space (0x20)
        end if;
    end function;

    -- Returns the 8-bit DATA byte to send for a given step. Steps 0-12
    -- are fixed (init commands + "68011008" + set-address); steps
    -- 13-16 are the four live digits, computed from sw_val. Always used
    -- as a full assignment at the call site (never sliced), so its
    -- internal index direction never matters.
    function step_data(step_idx : integer; sw_val : STD_LOGIC_VECTOR(15 downto 0))
        return STD_LOGIC_VECTOR is
    begin
        case step_idx is
            when 0  => return X"38"; -- Function set: 8-bit, 2 line, 5x8
            when 1  => return X"0C"; -- Display ON, cursor/blink off
            when 2  => return X"01"; -- Clear display
            when 3  => return X"06"; -- Entry mode: increment, no shift
            when 4  => return X"36"; -- '6'
            when 5  => return X"38"; -- '8'
            when 6  => return X"30"; -- '0'
            when 7  => return X"31"; -- '1'
            when 8  => return X"31"; -- '1'
            when 9  => return X"30"; -- '0'
            when 10 => return X"30"; -- '0'
            when 11 => return X"38"; -- '8'
            when 12 => return X"C0"; -- Set DDRAM address -> line 2, col 0
            when 13 => return bcd_char(sw_val(15 downto 12)); -- MSB digit, leftmost
            when 14 => return bcd_char(sw_val(11 downto 8));
            when 15 => return bcd_char(sw_val(7  downto 4));
            when 16 => return bcd_char(sw_val(3  downto 0));  -- LSB digit, rightmost
            when others => return X"00";
        end case;
    end function;

    type state_type is (POWERUP, SETUP, EPULSE, EXEC);
    signal state   : state_type := POWERUP;
    signal step    : integer range 0 to LAST_STEP := 0;
    signal counter : integer range 0 to T_POWERUP := 0;

    signal rs_i       : STD_LOGIC := '0';
    signal data_i     : STD_LOGIC_VECTOR(7 downto 0) := (others => '0');
    signal e_i        : STD_LOGIC := '0';
    signal sw_latched : STD_LOGIC_VECTOR(15 downto 0) := (others => '0');

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
                        counter    <= 0;
                        sw_latched <= sw;
                        rs_i       <= step_rs(0);
                        data_i     <= step_data(0, sw);
                        state      <= SETUP;
                    end if;

                when SETUP =>
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
                        if step = LAST_STEP then
                            -- One full line-2 refresh done: snapshot the
                            -- switches again and loop back to "set address"
                            -- for the next pass, so line 2 tracks live.
                            sw_latched <= sw;
                            step       <= LAST_INIT_STEP;
                            rs_i       <= step_rs(LAST_INIT_STEP);
                            data_i     <= step_data(LAST_INIT_STEP, sw);
                        else
                            step   <= step + 1;
                            rs_i   <= step_rs(step + 1);
                            data_i <= step_data(step + 1, sw_latched);
                        end if;
                        state <= SETUP;
                    end if;

            end case;
        end if;
    end process;

    rs   <= rs_i;
    data <= data_i;
    e    <= e_i;

end Behavioral;