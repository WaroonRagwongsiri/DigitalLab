library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- counter00_99_bcd's counter0_9 instances are now clocked by clk_50mhz
-- (the stable master clock); clk_20hz is a one-clk_50mhz-cycle-wide
-- synchronous enable pulse (same convention as last_output throughout the
-- divider chain), not a free-running clock in its own right. This tb
-- drives clk_50mhz continuously and pulses clk_20hz for exactly one
-- clk_50mhz period every TICK_PERIOD_CYCLES cycles, mirroring how the
-- real divider chain feeds a narrow tick pulse into this module.

entity tb_counter00_99_bcd is
end tb_counter00_99_bcd;

architecture sim of tb_counter00_99_bcd is
  constant CLK50_PERIOD        : time := 20 ns;
  constant TICK_PERIOD_CYCLES  : integer := 4; -- clk_50mhz cycles per synthetic 20Hz tick
  signal clk_50mhz : STD_LOGIC := '0';
  signal clk_20hz  : STD_LOGIC := '0';
  signal reset     : STD_LOGIC := '1';
  signal bcd_d1    : STD_LOGIC_VECTOR(3 downto 0);
  signal bcd_d0    : STD_LOGIC_VECTOR(3 downto 0);
begin

  dut : entity work.counter00_99_bcd
    port map (
      clk_20hz  => clk_20hz,
      clk_50mhz => clk_50mhz,
      reset     => reset,
      bcd_d1    => bcd_d1,
      bcd_d0    => bcd_d0
    );

  clk50_gen : process
  begin
    clk_50mhz <= '0';
    wait for CLK50_PERIOD/2;
    clk_50mhz <= '1';
    wait for CLK50_PERIOD/2;
  end process;

  tick_gen : process
  begin
    clk_20hz <= '0';
    wait for (TICK_PERIOD_CYCLES - 1) * CLK50_PERIOD;
    clk_20hz <= '1';
    wait for CLK50_PERIOD;
  end process;

  stim : process
    variable errors   : integer := 0;
    variable expected : integer;
    variable got      : integer;
  begin
    reset <= '1';
    wait for CLK50_PERIOD * 4;
    if bcd_d1 /= "0000" or bcd_d0 /= "0000" then
      report "FAIL: counter00_99_bcd does not reset to 00" severity error;
      errors := errors + 1;
    end if;
    reset <= '0';

    -- two full 00..99 cycles
    for i in 0 to 199 loop
      wait until falling_edge(clk_20hz);
      wait for CLK50_PERIOD/4; -- settle clear of the enable-sampling edge
      expected := i mod 100;
      got := to_integer(unsigned(bcd_d1)) * 10 + to_integer(unsigned(bcd_d0));
      if got /= expected then
        report "FAIL: counter00_99_bcd tick " & integer'image(i) &
               " got " & integer'image(got) &
               " expected " & integer'image(expected) severity error;
        errors := errors + 1;
      end if;
    end loop;

    if errors = 0 then
      report "PASS: counter00_99_bcd counts 00..99 and wraps correctly over 2 full cycles" severity note;
    end if;
    wait;
  end process;

end sim;
