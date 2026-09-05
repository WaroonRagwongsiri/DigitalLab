library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tb_n_2_digit_bcd_7seg_decoder is
end tb_n_2_digit_bcd_7seg_decoder;

architecture sim of tb_n_2_digit_bcd_7seg_decoder is
  constant CLK50_PERIOD       : time := 20 ns;
  constant TICK_PERIOD_CYCLES : integer := 4; -- clk50mhz cycles per synthetic clk_1khz tick

  signal current_bcd_d1 : STD_LOGIC_VECTOR(3 downto 0) := "0111"; -- 7 (tens)
  signal current_bcd_d0 : STD_LOGIC_VECTOR(3 downto 0) := "0011"; -- 3 (ones)
  signal clk_1khz       : STD_LOGIC := '0';
  signal clk50mhz       : STD_LOGIC := '0';
  signal segment_d3, segment_d2, segment_d1, segment_d0 : STD_LOGIC;
  signal d0, d1         : STD_LOGIC;
begin

  dut : entity work.n_2_digit_bcd_7seg_decoder
    port map (
      current_bcd_d1 => current_bcd_d1,
      current_bcd_d0 => current_bcd_d0,
      clk_1khz       => clk_1khz,
      clk50mhz       => clk50mhz,
      segment_d3     => segment_d3,
      segment_d2     => segment_d2,
      segment_d1     => segment_d1,
      segment_d0     => segment_d0,
      d0             => d0,
      d1             => d1
    );

  clk50_gen : process
  begin
    clk50mhz <= '0';
    wait for CLK50_PERIOD/2;
    clk50mhz <= '1';
    wait for CLK50_PERIOD/2;
  end process;

  -- clk_1khz is a one-clk50mhz-cycle-wide tick pulse (matching the real
  -- divider chain's convention), not a free-running clock in its own right.
  tick_gen : process
  begin
    clk_1khz <= '0';
    wait for (TICK_PERIOD_CYCLES - 1) * CLK50_PERIOD;
    clk_1khz <= '1';
    wait for CLK50_PERIOD;
  end process;

  checker : process
    variable errors : integer := 0;
    variable nibble  : STD_LOGIC_VECTOR(3 downto 0);
  begin
    for i in 0 to 5 loop
      wait until rising_edge(clk_1khz);
      -- n22_q now toggles on clk50mhz (sampling clk_1khz as an enable), not
      -- on clk_1khz's own edge - settle a full clk50mhz cycle clear of the
      -- tick's rising edge before the mux output is guaranteed updated.
      wait for CLK50_PERIOD + 1 ns;

      if (d0 = '1' and d1 = '1') or (d0 = '0' and d1 = '0') then
        report "FAIL: n_2_digit_bcd_7seg_decoder d0/d1 digit selects are not mutually exclusive" severity error;
        errors := errors + 1;
      end if;

      nibble := segment_d3 & segment_d2 & segment_d1 & segment_d0;
      if d0 = '1' then
        -- d0 selects the ones digit: segments should show current_bcd_d0
        if nibble /= current_bcd_d0 then
          report "FAIL: n_2_digit_bcd_7seg_decoder shows the wrong nibble while d0 (ones digit) is selected " &
                 "- looks like it is routing current_bcd_d1 (tens) instead" severity error;
          errors := errors + 1;
        end if;
      else
        -- d1 selects the tens digit: segments should show current_bcd_d1
        if nibble /= current_bcd_d1 then
          report "FAIL: n_2_digit_bcd_7seg_decoder shows the wrong nibble while d1 (tens digit) is selected " &
                 "- looks like it is routing current_bcd_d0 (ones) instead" severity error;
          errors := errors + 1;
        end if;
      end if;
    end loop;

    if errors = 0 then
      report "PASS: n_2_digit_bcd_7seg_decoder multiplexes d1/d0 nibbles correctly" severity note;
    end if;
    wait;
  end process;

end sim;
