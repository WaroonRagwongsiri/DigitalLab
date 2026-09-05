library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tb_debounce_toggle is
end tb_debounce_toggle;

architecture sim of tb_debounce_toggle is
  constant CLK50_PERIOD : time := 2 ns;
  constant CLK1K_PERIOD : time := 40 ns;

  signal clk_50mhz     : STD_LOGIC := '0';
  signal clk_1khz      : STD_LOGIC := '0';
  signal sw_in         : STD_LOGIC := '0';
  signal toggle_output : STD_LOGIC;
begin

  dut : entity work.debounce_toggle
    port map (
      sw_in         => sw_in,
      clk_50mhz     => clk_50mhz,
      clk_1khz      => clk_1khz,
      toggle_output => toggle_output
    );

  clk50_gen : process
  begin
    clk_50mhz <= '0';
    wait for CLK50_PERIOD/2;
    clk_50mhz <= '1';
    wait for CLK50_PERIOD/2;
  end process;

  clk1k_gen : process
  begin
    clk_1khz <= '0';
    wait for CLK1K_PERIOD/2;
    clk_1khz <= '1';
    wait for CLK1K_PERIOD/2;
  end process;

  stim : process
    variable errors     : integer := 0;
    variable before_val : STD_LOGIC;
  begin
    wait for CLK50_PERIOD * 10;
    if toggle_output /= '0' then
      report "FAIL: debounce_toggle does not start at 0" severity error;
      errors := errors + 1;
    end if;

    -- clean press #1: hold long enough to pass debounce, then release
    before_val := toggle_output;
    sw_in <= '1';
    wait for CLK1K_PERIOD * 20;
    if toggle_output = before_val then
      report "FAIL: debounce_toggle did not flip on press #1" severity error;
      errors := errors + 1;
    end if;
    sw_in <= '0';
    wait for CLK1K_PERIOD * 20;
    if toggle_output /= not before_val then
      report "FAIL: debounce_toggle changed state again on release of press #1" severity error;
      errors := errors + 1;
    end if;

    -- clean press #2: should flip back
    before_val := toggle_output;
    sw_in <= '1';
    wait for CLK1K_PERIOD * 20;
    if toggle_output = before_val then
      report "FAIL: debounce_toggle did not flip on press #2" severity error;
      errors := errors + 1;
    end if;
    sw_in <= '0';
    wait for CLK1K_PERIOD * 20;

    if errors = 0 then
      report "PASS: debounce_toggle flips exactly once per qualifying press" severity note;
    end if;
    wait;
  end process;

end sim;
