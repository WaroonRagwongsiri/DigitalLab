library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- Full-chip reproduction testbench. Uses the TRUE 50 MHz clock period so
-- that simulated time maps 1:1 onto real wall-clock time, letting us
-- directly measure the interval between BCD increments and compare it
-- against the intended 50 ms (20 Hz) tick - i.e. reproduce (or disprove)
-- the reported "00-99 in ~6s instead of ~100s" bug at the top level.

entity tb_lab6 is
end tb_lab6;

architecture sim of tb_lab6 is
  constant CLK_PERIOD : time := 20 ns; -- true 50 MHz board clock

  signal clk50mhz       : STD_LOGIC := '0';
  signal sw_target_bcd  : STD_LOGIC_VECTOR(7 downto 0) := std_logic_vector(to_unsigned(3, 8));
  signal btn_start_stop : STD_LOGIC := '0';
  signal led_status     : STD_LOGIC;
  signal a, b, c, d, e, f, g : STD_LOGIC;
  signal d0, d1, d2, d3 : STD_LOGIC;
begin

  dut : entity work.lab6
    port map (
      clk50mhz       => clk50mhz,
      sw_target_bcd  => sw_target_bcd,
      btn_start_stop => btn_start_stop,
      led_status     => led_status,
      a => a, b => b, c => c, d => d, e => e, f => f, g => g,
      d0 => d0, d1 => d1, d2 => d2, d3 => d3
    );

  clk_gen : process
  begin
    clk50mhz <= '0';
    wait for CLK_PERIOD/2;
    clk50mhz <= '1';
    wait for CLK_PERIOD/2;
  end process;

  monitor : process
    constant TARGET        : integer := 3; -- matches sw_target_bcd above
    constant NUM_INTERVALS : integer := TARGET + 1; -- one full 0..target..wrap loop

    variable t_prev, t_now : time;
    variable prev_pattern, pattern : STD_LOGIC_VECTOR(6 downto 0);
    variable got_first : boolean := false;
    variable measured  : time;
    variable errors    : integer := 0;
  begin
    -- start the timer with a clean, held button press. debounce_button's
    -- internal n_8_bit_sync_counter_with_target needs the button held
    -- steady for its full target count (50, i.e. 50 clk_1khz/~1ms ticks
    -- = ~50 ms) before toggle_output registers the press - a short couple
    -- of ms hold (as a real button bounce settles in) never latches.
    wait for 1 us;
    btn_start_stop <= '1';
    wait for 60 ms;
    btn_start_stop <= '0';

    -- sample the segment pattern each time the "ones" digit slot (d0) is
    -- active, and time how long it stays constant before it changes - that
    -- is the real wall-clock period of one BCD increment, regardless of
    -- which underlying digit ends up routed to that slot. Walk through one
    -- full 0..target..wrap loop (NUM_INTERVALS changes) so both the steady
    -- increments and the wrap-around interval get measured.
    for n in 1 to NUM_INTERVALS loop
      loop
        wait until rising_edge(d0);
        wait for 100 us; -- settle well clear of the mux/decoder switching edge
        pattern := a & b & c & d & e & f & g;
        if not got_first then
          prev_pattern := pattern;
          t_prev := now;
          got_first := true;
        elsif pattern /= prev_pattern then
          t_now := now;
          exit;
        end if;
      end loop;

      measured := t_now - t_prev;
      report "NOTE: lab6 interval " & integer'image(n) & "/" & integer'image(NUM_INTERVALS) &
             " = " & integer'image(measured / 1 ns) &
             " ns (expected ~50,000,000 ns / 50 ms if the clk_20hz divide chain is correct)" severity note;

      if measured <= 45 ms or measured >= 55 ms then
        report "FAIL: lab6 interval " & integer'image(n) & " is " & integer'image(measured / 1 ns) &
               " ns, not the intended ~50,000,000 ns - this reproduces the reported timing bug" severity error;
        errors := errors + 1;
      end if;

      prev_pattern := pattern;
      t_prev := t_now;
    end loop;

    if errors = 0 then
      report "PASS: lab6 held its full 0.." & integer'image(TARGET) &
             " count loop at the intended ~50 ms (20 Hz) tick" severity note;
    end if;

    wait;
  end process;

end sim;
