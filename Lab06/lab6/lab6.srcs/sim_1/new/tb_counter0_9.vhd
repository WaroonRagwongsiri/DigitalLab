library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tb_counter0_9 is
end tb_counter0_9;

architecture sim of tb_counter0_9 is
  constant CLK_PERIOD : time := 20 ns;
  signal clk          : STD_LOGIC := '0';
  signal reset        : STD_LOGIC := '1';
  signal current_bcd  : STD_LOGIC_VECTOR(3 downto 0);
  signal limit_reach  : STD_LOGIC;
begin

  -- note: counter0_9 clocks on falling_edge(clk), matching the RTL
  dut : entity work.counter0_9
    port map (
      last_output => '1',
      clk         => clk,
      reset       => reset,
      current_bcd => current_bcd,
      limit_reach => limit_reach
    );

  clk_gen : process
  begin
    clk <= '0';
    wait for CLK_PERIOD/2;
    clk <= '1';
    wait for CLK_PERIOD/2;
  end process;

  stim : process
    variable errors   : integer := 0;
    variable expected : integer;
  begin
    reset <= '1';
    wait for CLK_PERIOD * 2;
    if current_bcd /= "0000" then
      report "FAIL: counter0_9 does not reset to 0000" severity error;
      errors := errors + 1;
    end if;
    reset <= '0';

    -- two full 0..9 cycles, sampled shortly after each falling edge
    for i in 0 to 19 loop
      wait until falling_edge(clk);
      wait for 1 ns;
      expected := i mod 10;
      if to_integer(unsigned(current_bcd)) /= expected then
        report "FAIL: counter0_9 count " & integer'image(i) &
               " got " & integer'image(to_integer(unsigned(current_bcd))) &
               " expected " & integer'image(expected) severity error;
        errors := errors + 1;
      end if;
      if expected = 9 then
        if limit_reach /= '1' then
          report "FAIL: counter0_9 limit_reach not asserted at count 9" severity error;
          errors := errors + 1;
        end if;
      else
        if limit_reach /= '0' then
          report "FAIL: counter0_9 limit_reach asserted early at count " & integer'image(expected) severity error;
          errors := errors + 1;
        end if;
      end if;
    end loop;

    -- async reset asserted mid-count (not aligned to a clock edge)
    wait until falling_edge(clk);
    wait for 1 ns;
    reset <= '1';
    wait for 1 ns;
    if current_bcd /= "0000" then
      report "FAIL: counter0_9 asynchronous reset did not clear the count immediately" severity error;
      errors := errors + 1;
    end if;
    reset <= '0';

    if errors = 0 then
      report "PASS: counter0_9 sequence, limit_reach, and async reset all correct" severity note;
    end if;
    wait;
  end process;

end sim;
