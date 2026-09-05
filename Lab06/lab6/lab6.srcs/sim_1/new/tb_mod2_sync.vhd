library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tb_mod2_sync is
end tb_mod2_sync;

architecture sim of tb_mod2_sync is
  constant CLK_PERIOD : time := 20 ns;
  signal clk         : STD_LOGIC := '0';
  signal last_output : STD_LOGIC := '1';
  signal mod2_out    : STD_LOGIC;
begin

  dut : entity work.mod2_sync
    port map (
      last_output => last_output,
      clk         => clk,
      mod2_out    => mod2_out
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
    -- check 2 full output periods, not just one, so a one-off glitch and a
    -- consistent wrong ratio show up differently
    wait until rising_edge(mod2_out);
    t_prev := now;
    for i in 1 to 2 loop
      wait until rising_edge(mod2_out);
      t_edge := now;
      cycles := (t_edge - t_prev) / CLK_PERIOD;
      if cycles /= 2 then
        report "FAIL: mod2_sync period " & integer'image(i) & " = " & integer'image(cycles) &
               " input clocks, expected 2" severity error;
        errors := errors + 1;
      end if;
      t_prev := t_edge;
    end loop;

    if errors = 0 then
      report "PASS: mod2_sync period = 2 input clocks as expected" severity note;
    end if;
    wait;
  end process;

end sim;
