library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tb_mod50k_sync is
end tb_mod50k_sync;

architecture sim of tb_mod50k_sync is
  constant CLK_PERIOD : time := 10 ns;
  signal clk         : STD_LOGIC := '0';
  signal clk_mod50k  : STD_LOGIC;
begin

  dut : entity work.mod50k_sync
    port map (
      clk        => clk,
      clk_mod50k => clk_mod50k
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
    wait until rising_edge(clk_mod50k);
    t_prev := now;
    for i in 1 to 2 loop
      wait until rising_edge(clk_mod50k);
      t_edge := now;
      cycles := (t_edge - t_prev) / CLK_PERIOD;
      if cycles /= 50000 then
        report "FAIL: mod50k_sync period " & integer'image(i) & " = " & integer'image(cycles) &
               " input clocks, expected 50000" severity error;
        errors := errors + 1;
      end if;
      t_prev := t_edge;
    end loop;

    if errors = 0 then
      report "PASS: mod50k_sync period = 50000 input clocks as expected" severity note;
    end if;
    wait;
  end process;

end sim;
