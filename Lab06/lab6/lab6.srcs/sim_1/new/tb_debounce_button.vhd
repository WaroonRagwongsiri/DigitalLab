library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tb_debounce_button is
end tb_debounce_button;

architecture sim of tb_debounce_button is
  constant CLK50_PERIOD : time := 2 ns;
  constant CLK1K_PERIOD : time := 40 ns;

  signal clk_50mhz       : STD_LOGIC := '0';
  signal clk_1khz        : STD_LOGIC := '0';
  signal button_signal   : STD_LOGIC := '0';
  signal debounce_signal : STD_LOGIC;
begin

  dut : entity work.debounce_button
    port map (
      button_signal   => button_signal,
      clk_50mhz       => clk_50mhz,
      clk_1khz        => clk_1khz,
      debounce_signal => debounce_signal
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
    variable errors : integer := 0;
  begin
    -- a burst of short glitches, each far shorter than one clk_1khz period,
    -- should never accumulate enough valid samples to validate the press
    for i in 0 to 5 loop
      button_signal <= '1';
      wait for 3 ns;
      button_signal <= '0';
      wait for 7 ns;
    end loop;
    if debounce_signal /= '0' then
      report "FAIL: debounce_button asserted debounce_signal on glitchy input" severity error;
      errors := errors + 1;
    end if;

    -- a solidly stable press held across many clk_1khz cycles should eventually validate
    button_signal <= '1';
    wait for CLK1K_PERIOD * 20;
    if debounce_signal /= '1' then
      report "FAIL: debounce_button never asserted debounce_signal on a stable held press" severity error;
      errors := errors + 1;
    end if;

    -- releasing the button should clear the debounced output promptly
    button_signal <= '0';
    wait for CLK50_PERIOD * 10;
    if debounce_signal /= '0' then
      report "FAIL: debounce_button did not clear debounce_signal on release" severity error;
      errors := errors + 1;
    end if;

    if errors = 0 then
      report "PASS: debounce_button rejects glitches and validates a stable press" severity note;
    end if;
    wait;
  end process;

end sim;
