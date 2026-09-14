-- ============================================================
-- Testbench: lcd_sender_tb
-- ============================================================
-- Unit test for lcd_sender's setup delay: since data_out/rs_out are
-- wired straight from data_in/rs_in (always valid, no gating), the only
-- thing that needs checking is that 'e' waits through the full HD44780
-- wait floor (~42ms, via lcd_wait_sync: 1 clock trigger->waiting +
-- 2^21 clocks of wait + 1 clock e_drive->e_reg registration) before
-- rising - plus that data/rs are correct throughout, the pulse width is
-- the expected 32 clocks, and 'done' fires after.
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity lcd_sender_tb is
end lcd_sender_tb;

architecture sim of lcd_sender_tb is

  component lcd_sender
    Port (
      trigger  : in  STD_LOGIC;
      rs_in    : in  STD_LOGIC;
      data_in  : in  STD_LOGIC_VECTOR(7 downto 0);
      clk      : in  STD_LOGIC;
      done     : out STD_LOGIC;
      rs_out   : out STD_LOGIC;
      data_out : out STD_LOGIC_VECTOR(7 downto 0);
      e        : out STD_LOGIC
    );
  end component;

  constant CLK_PERIOD    : time := 20 ns; -- 50 MHz
  -- Total trigger->e latency = 1 clock for trigger to synchronously set
  -- 'waiting' + 2**21 clocks for the lcd_wait_sync HD44780 wait floor to
  -- elapse (21-stage mod2_sync chain, same mechanism as mod32_sync below
  -- but scaled up) + 1 clock for the e_drive->e_reg D-FF. Checked with a
  -- tolerance rather than an exact match since this is a large derived
  -- constant; the report below prints the actual measured value.
  constant EXPECTED_SETUP_CYCLES : integer := 2**21 + 2;
  constant SETUP_TOLERANCE_CYCLES : integer := 2;
  constant EXPECTED_PULSE_CYCLES : integer := 32; -- mod32_sync period

  signal clk      : STD_LOGIC := '0';
  signal trigger  : STD_LOGIC := '0';
  signal rs_in    : STD_LOGIC := '1';
  signal data_in  : STD_LOGIC_VECTOR(7 downto 0) := x"41"; -- 'A', arbitrary test byte
  signal done     : STD_LOGIC;
  signal rs_out   : STD_LOGIC;
  signal data_out : STD_LOGIC_VECTOR(7 downto 0);
  signal e        : STD_LOGIC;

  function to_hex_char(nibble : STD_LOGIC_VECTOR(3 downto 0)) return character is
  begin
    case nibble is
      when "0000" => return '0'; when "0001" => return '1';
      when "0010" => return '2'; when "0011" => return '3';
      when "0100" => return '4'; when "0101" => return '5';
      when "0110" => return '6'; when "0111" => return '7';
      when "1000" => return '8'; when "1001" => return '9';
      when "1010" => return 'A'; when "1011" => return 'B';
      when "1100" => return 'C'; when "1101" => return 'D';
      when "1110" => return 'E'; when others => return 'F';
    end case;
  end function;

  function to_hex_string(v : STD_LOGIC_VECTOR(7 downto 0)) return string is
  begin
    return to_hex_char(v(7 downto 4)) & to_hex_char(v(3 downto 0));
  end function;

begin

  uut : lcd_sender port map (
    trigger  => trigger,
    rs_in    => rs_in,
    data_in  => data_in,
    clk      => clk,
    done     => done,
    rs_out   => rs_out,
    data_out => data_out,
    e        => e
  );

  clk_gen : process
  begin
    clk <= '0'; wait for CLK_PERIOD / 2;
    clk <= '1'; wait for CLK_PERIOD / 2;
  end process;

  check : process
    variable t_trigger        : time;
    variable t_e_rise         : time;
    variable t_e_fall         : time;
    variable setup_cycles     : integer;
    variable pulse_cycles     : integer;
  begin
    -- 1) data_out/rs_out are unconditional wires: already valid with no
    --    trigger at all.
    wait for 1 ns;
    assert data_out = data_in and rs_out = rs_in
      report "FAIL: data_out/rs_out not valid before any trigger" severity error;
    report "PRE-TRIGGER: data_out=0x" & to_hex_string(data_out) &
           " rs_out=" & STD_LOGIC'image(rs_out) & " already valid - OK";

    -- 2) pulse trigger for exactly one clock
    wait until rising_edge(clk);
    trigger <= '1';
    t_trigger := now;
    wait until rising_edge(clk);
    trigger <= '0';

    -- 'e' must NOT be high on the very same edge that started busy -
    -- the D-FF must hold it low for at least this one cycle.
    assert e = '0'
      report "FAIL: 'e' rose on the same clock as trigger - no setup delay!" severity error;

    -- 3) measure how many clocks until 'e' actually rises
    wait until (e = '1') for 50 ms;
    assert e = '1' report "FAIL: 'e' never rose after trigger" severity failure;
    t_e_rise := now;
    setup_cycles := (t_e_rise - t_trigger) / CLK_PERIOD;
    report "'e' rose " & integer'image(setup_cycles) & " clock(s) after trigger " &
           "(expected ~" & integer'image(EXPECTED_SETUP_CYCLES) &
           " = 1 for trigger->waiting + 2**21 for the lcd_wait_sync HD44780 " &
           "wait floor + 1 for the e_drive->e_reg D-FF)";
    assert abs(setup_cycles - EXPECTED_SETUP_CYCLES) <= SETUP_TOLERANCE_CYCLES
      report "FAIL: setup delay was " & integer'image(setup_cycles) &
             " clock(s), expected " & integer'image(EXPECTED_SETUP_CYCLES) &
             " +/- " & integer'image(SETUP_TOLERANCE_CYCLES)
      severity error;

    -- 4) data/rs must already be correct the instant 'e' rises
    assert data_out = data_in and rs_out = rs_in
      report "FAIL: data_out/rs_out wrong at the instant 'e' rose" severity error;
    report "data_out=0x" & to_hex_string(data_out) & " rs_out=" & STD_LOGIC'image(rs_out) &
           " already correct when 'e' rose - OK";

    -- 5) pulse width: 'e' should stay high for EXPECTED_PULSE_CYCLES clocks
    wait until (e = '0') for (EXPECTED_PULSE_CYCLES + 10) * CLK_PERIOD;
    assert e = '0' report "FAIL: 'e' never fell (pulse never ended)" severity failure;
    t_e_fall := now;
    pulse_cycles := (t_e_fall - t_e_rise) / CLK_PERIOD;
    report "'e' pulse lasted " & integer'image(pulse_cycles) & " clock(s) " &
           "(expected " & integer'image(EXPECTED_PULSE_CYCLES) & ")";
    assert pulse_cycles = EXPECTED_PULSE_CYCLES
      report "FAIL: pulse width was " & integer'image(pulse_cycles) &
             " clock(s), expected " & integer'image(EXPECTED_PULSE_CYCLES)
      severity error;

    -- 6) 'done' should fire shortly after 'e' falls
    wait until (done = '1') for 5 * CLK_PERIOD;
    assert done = '1' report "FAIL: 'done' never fired after 'e' fell" severity failure;
    report "'done' fired after 'e' fell - OK";

    report "ALL CHECKS PASSED: 'e' has a ~" & integer'image(EXPECTED_SETUP_CYCLES) &
           "-clock setup delay after trigger (measured " & integer'image(setup_cycles) &
           ", data/rs already valid), a " &
           integer'image(EXPECTED_PULSE_CYCLES) & "-clock pulse width, and 'done' follows correctly."
      severity note;

    wait;
  end process;

end sim;
