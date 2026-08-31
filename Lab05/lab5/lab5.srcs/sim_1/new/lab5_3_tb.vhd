-- ============================================================
-- Testbench: lab5_3_tb
-- ============================================================
-- Diagnostic-only testbench (adds no fixes, changes no design sources).
-- Goal: determine whether the "counter changes every ~0.5s instead of 1s"
-- symptom comes from counter_2345679 itself, or from the mod50m_sync
-- divide chain feeding it a bad/glitchy clock.
--
-- Path 1 (ISOLATED): counter_2345679 driven directly by a clean 20 ns
--   (50 MHz) clock, independent of any divider. Every output change is
--   logged so the counting sequence can be read straight off the
--   transcript and compared against known-good behavior.
--
-- Path 2 (CHAIN): mod50m_sync -> counter_2345679, wired exactly as in
--   lab5_3.vhd. Both clk_mod50m itself and the counter outputs are
--   monitored, each report including the time interval since the
--   previous event, so a wrong-rate divided clock and a counter that is
--   catching spurious edges show up as two distinguishable signatures.
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity lab5_3_tb is
end lab5_3_tb;

architecture sim of lab5_3_tb is

  constant CLK_PERIOD : time    := 20 ns;           -- 50 MHz board clock
  constant ISO_CLOCKS : integer := 40;               -- edges to run the isolated path
  constant SIM_TIME   : time    := 4_000_000_000 ns; -- 4 s of chain-path simulated time

  -- ---- Path 1: isolated counter_2345679 on its own clean clock ----
  signal clk_iso  : STD_LOGIC := '0';
  signal iso_done : boolean   := false;
  signal q3_iso, q2_iso, q1_iso, q0_iso : STD_LOGIC;

  -- ---- Path 2: full chain, mod50m_sync -> counter_2345679 ----
  signal clk_chain  : STD_LOGIC := '0';
  signal sim_done   : boolean   := false;
  signal clk_mod50m : STD_LOGIC;
  signal q3_chain, q2_chain, q1_chain, q0_chain : STD_LOGIC;

begin

  ------------------------------------------------------------------
  -- Clock generators
  ------------------------------------------------------------------
  clk_iso   <= not clk_iso   after CLK_PERIOD / 2 when not iso_done else clk_iso;
  clk_chain <= not clk_chain after CLK_PERIOD / 2 when not sim_done else clk_chain;

  -- stop the isolated clock after ISO_CLOCKS rising edges so the
  -- transcript for Path 1 stays short and readable
  iso_clock_gate : process(clk_iso)
    variable cnt : integer := 0;
  begin
    if rising_edge(clk_iso) then
      cnt := cnt + 1;
      if cnt >= ISO_CLOCKS then
        iso_done <= true;
      end if;
    end if;
  end process;

  ------------------------------------------------------------------
  -- Path 1: isolated counter_2345679
  ------------------------------------------------------------------
  uut_iso : entity work.counter_2345679
    port map (
      clk    => clk_iso,
      q3_msb => q3_iso,
      q2     => q2_iso,
      q1     => q1_iso,
      q0_lsb => q0_iso
    );

  iso_monitor : process(q3_iso, q2_iso, q1_iso, q0_iso)
    variable val : integer;
  begin
    val := to_integer(unsigned'(q3_iso & q2_iso & q1_iso & q0_iso));
    report "ISOLATED counter @ " & time'image(now) &
           " => " & integer'image(val);
  end process;

  ------------------------------------------------------------------
  -- Path 2: full divide chain -> counter_2345679, wired as in lab5_3.vhd
  ------------------------------------------------------------------
  uut_divider : entity work.mod50m_sync
    port map (
      clk        => clk_chain,
      clk_mod50m => clk_mod50m
    );

  uut_chain : entity work.counter_2345679
    port map (
      clk    => clk_mod50m,
      q3_msb => q3_chain,
      q2     => q2_chain,
      q1     => q1_chain,
      q0_lsb => q0_chain
    );

  clk_mod50m_monitor : process(clk_mod50m)
    variable last_time : time    := 0 ns;
    variable first      : boolean := true;
  begin
    if first then
      report "clk_mod50m @ " & time'image(now) &
             " -> " & STD_LOGIC'image(clk_mod50m) & " (initial)";
      first := false;
    else
      report "clk_mod50m @ " & time'image(now) &
             " -> " & STD_LOGIC'image(clk_mod50m) &
             " (interval since last transition = " &
             time'image(now - last_time) & ")";
    end if;
    last_time := now;
  end process;

  chain_counter_monitor : process(q3_chain, q2_chain, q1_chain, q0_chain)
    variable val        : integer;
    variable last_time  : time    := 0 ns;
    variable first       : boolean := true;
  begin
    val := to_integer(unsigned'(q3_chain & q2_chain & q1_chain & q0_chain));
    if first then
      report "CHAIN counter changed @ " & time'image(now) &
             " => " & integer'image(val) & " (initial)";
      first := false;
    else
      report "CHAIN counter changed @ " & time'image(now) &
             " => " & integer'image(val) &
             " (interval since previous change = " &
             time'image(now - last_time) & ")";
    end if;
    last_time := now;
  end process;

  ------------------------------------------------------------------
  -- Overall simulation length
  ------------------------------------------------------------------
  stim_proc : process
  begin
    wait for SIM_TIME;
    sim_done <= true;
    report "Simulation finished at " & time'image(now);
    wait;
  end process;

end architecture sim;
