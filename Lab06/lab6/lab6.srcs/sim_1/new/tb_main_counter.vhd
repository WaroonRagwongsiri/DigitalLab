library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- main_counter resets counter00_99_bcd through n_8bit_1_clk_delay + a
-- combinational compare against target_bcd. Because the compare uses a
-- value that is delayed by only ONE clk_50mhz cycle relative to the
-- clk_20hz-driven counter, the asynchronous reset it drives can fire
-- within a couple of clk_50mhz cycles of reaching the target - i.e. well
-- before the counter would ever hold the target value for a full
-- clk_20hz tick. This testbench asserts the *intended* behavior (count
-- 0..target, holding each value for one clk_20hz period, then wrap) and
-- is expected to catch that race if present.
--
-- clk_20hz is a one-clk_50mhz-cycle-wide tick pulse (same convention as
-- last_output throughout the divider chain), not a free-running clock -
-- counter00_99_bcd samples it as a synchronous count-enable on the stable
-- clk_50mhz. It must be driven as a narrow pulse here, matching the real
-- n5_o tick from main_controller, not as a 50%-duty square wave.

entity tb_main_counter is
end tb_main_counter;

architecture sim of tb_main_counter is
  constant CLK50_PERIOD : time := 20 ns;   -- true 50 MHz period
  constant CLK20_PERIOD : time := 50 ms;   -- true 20 Hz period
  constant TARGET       : integer := 20;   -- 00-20, ~1.05 s ideal

  signal clk_50mhz  : STD_LOGIC := '0';
  signal clk_20hz   : STD_LOGIC := '0';
  -- target_bcd is packed BCD (tens digit in the upper nibble, ones digit in
  -- the lower nibble), matching current_d1 & current_d0 - NOT a plain binary
  -- encoding of TARGET, so it must be built digit-by-digit for TARGET >= 10.
  signal target_bcd : STD_LOGIC_VECTOR(7 downto 0) :=
    std_logic_vector(to_unsigned(TARGET / 10, 4)) & std_logic_vector(to_unsigned(TARGET mod 10, 4));
  signal current_d1 : STD_LOGIC_VECTOR(3 downto 0);
  signal current_d0 : STD_LOGIC_VECTOR(3 downto 0);
begin

  dut : entity work.main_counter
    port map (
      target_bcd => target_bcd,
      clk_20hz   => clk_20hz,
      clk_50mhz  => clk_50mhz,
      current_d1 => current_d1,
      current_d0 => current_d0
    );

  clk50_gen : process
  begin
    clk_50mhz <= '0';
    wait for CLK50_PERIOD/2;
    clk_50mhz <= '1';
    wait for CLK50_PERIOD/2;
  end process;

  clk20_gen : process
  begin
    clk_20hz <= '0';
    wait for CLK20_PERIOD - CLK50_PERIOD;
    clk_20hz <= '1';
    wait for CLK50_PERIOD;
  end process;

  checker : process
    constant FULL_LOOP_TICKS : integer := TARGET + 1;
    constant NUM_TICKS       : integer := FULL_LOOP_TICKS + FULL_LOOP_TICKS/2; -- one full loop + a half loop
    variable errors   : integer := 0;
    variable got      : integer;
    variable expected : integer;
  begin
    for n in 1 to NUM_TICKS loop
      wait until falling_edge(clk_20hz);
      wait for 100 ns; -- settle well clear of the clk_50mhz delay/compare path, still << CLK20_PERIOD
      got := to_integer(unsigned(current_d1)) * 10 + to_integer(unsigned(current_d0));
      expected := n mod (TARGET + 1);
      if got /= expected then
        -- severity error (not failure) so the run continues through the full
        -- requested window instead of halting at the first mismatch
        report "FAIL: main_counter tick " & integer'image(n) &
               " got " & integer'image(got) &
               " expected " & integer'image(expected) &
               " (target should be held for a full clk_20hz tick before wrapping)" severity error;
        errors := errors + 1;
      end if;
    end loop;

    if errors = 0 then
      report "PASS: main_counter counts 0.." & integer'image(TARGET) & " and wraps once per clk_20hz cycle" severity note;
    end if;
    wait;
  end process;

end sim;
