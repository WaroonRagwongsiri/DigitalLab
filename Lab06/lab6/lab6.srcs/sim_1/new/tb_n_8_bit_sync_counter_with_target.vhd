library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tb_n_8_bit_sync_counter_with_target is
end tb_n_8_bit_sync_counter_with_target;

architecture sim of tb_n_8_bit_sync_counter_with_target is
  constant CLK_PERIOD : time := 20 ns;
  constant TARGET     : integer := 5;

  signal clk           : STD_LOGIC := '0';
  signal trigger       : STD_LOGIC := '0';
  signal reset         : STD_LOGIC := '1';
  signal target_vec    : STD_LOGIC_VECTOR(7 downto 0) := std_logic_vector(to_unsigned(TARGET, 8));
  signal limit_reached : STD_LOGIC;
  signal current       : STD_LOGIC_VECTOR(7 downto 0);
begin

  dut : entity work.n_8_bit_sync_counter_with_target
    port map (
      trigger       => trigger,
      target        => target_vec,
      clk           => clk,
      reset         => reset,
      limit_reached => limit_reached,
      current       => current
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
    reset   <= '1';
    trigger <= '0';
    wait for CLK_PERIOD * 2;
    if to_integer(unsigned(current)) /= 0 then
      report "FAIL: n_8_bit_sync_counter_with_target does not reset to 0" severity error;
      errors := errors + 1;
    end if;
    reset   <= '0';
    trigger <= '1';

    for i in 0 to 3 * (TARGET + 1) - 1 loop
      wait until rising_edge(clk);
      wait for 1 ns;
      expected := i mod (TARGET + 1);
      if to_integer(unsigned(current)) /= expected then
        report "FAIL: n_8_bit_sync_counter_with_target tick " & integer'image(i) &
               " got " & integer'image(to_integer(unsigned(current))) &
               " expected " & integer'image(expected) severity error;
        errors := errors + 1;
      end if;
      if expected = TARGET then
        if limit_reached /= '1' then
          report "FAIL: n_8_bit_sync_counter_with_target limit_reached not set at target" severity error;
          errors := errors + 1;
        end if;
      else
        if limit_reached /= '0' then
          report "FAIL: n_8_bit_sync_counter_with_target limit_reached set early at " & integer'image(expected) severity error;
          errors := errors + 1;
        end if;
      end if;
    end loop;

    if errors = 0 then
      report "PASS: n_8_bit_sync_counter_with_target counts 0.." & integer'image(TARGET) &
             ", flags limit_reached, and self-clears" severity note;
    end if;
    wait;
  end process;

end sim;
