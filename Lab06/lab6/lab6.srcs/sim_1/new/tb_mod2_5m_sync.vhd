library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- Measures the actual divide ratio of the clk_20hz source chain.
-- This is the prime suspect for the "00-99 in ~6s instead of ~100s" bug:
-- 100 counts at 20 Hz should take 5s, closely matching what was observed,
-- so confirming (or refuting) a true /2,500,000 ratio here is the highest
-- priority check in this whole testbench suite.

entity tb_mod2_5m_sync is
end tb_mod2_5m_sync;

architecture sim of tb_mod2_5m_sync is
  constant CLK_PERIOD : time := 20 ns; -- true 50 MHz period
  signal clk         : STD_LOGIC := '0';
  signal clk_mod25m  : STD_LOGIC;
begin

  dut : entity work.mod2_5m_sync
    port map (
      clk        => clk,
      clk_mod25m => clk_mod25m
    );

  clk_gen : process
  begin
    clk <= '0';
    wait for CLK_PERIOD/2;
    clk <= '1';
    wait for CLK_PERIOD/2;
  end process;

  checker : process
    variable t_prev, t_edge : time;
    variable cycles         : integer;
    variable errors         : integer := 0;
  begin
    wait until rising_edge(clk_mod25m);
    t_prev := now;
    for i in 1 to 2 loop
      wait until rising_edge(clk_mod25m);
      t_edge := now;
      cycles := (t_edge - t_prev) / CLK_PERIOD;
      if cycles /= 2500000 then
        report "FAIL: mod2_5m_sync period " & integer'image(i) & " = " & integer'image(cycles) &
               " input clocks, expected 2,500,000 (this directly explains a wrong clk_20hz rate)" severity error;
        errors := errors + 1;
      end if;
      t_prev := t_edge;
    end loop;

    if errors = 0 then
      report "PASS: mod2_5m_sync period = 2,500,000 input clocks as expected" severity note;
    end if;
    wait;
  end process;

end sim;
