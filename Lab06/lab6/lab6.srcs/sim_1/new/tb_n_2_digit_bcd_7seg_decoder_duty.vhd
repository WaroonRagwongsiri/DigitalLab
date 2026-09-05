library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tb_n_2_digit_bcd_7seg_decoder_duty is
end tb_n_2_digit_bcd_7seg_decoder_duty;

architecture sim of tb_n_2_digit_bcd_7seg_decoder_duty is
  constant CLK_PERIOD : time := 20 ns;
  signal clk50mhz : STD_LOGIC := '0';
  signal clk_mod50k : STD_LOGIC;
  signal current_bcd_d1 : STD_LOGIC_VECTOR(3 downto 0) := "0111";
  signal current_bcd_d0 : STD_LOGIC_VECTOR(3 downto 0) := "0011";
  signal segment_d3, segment_d2, segment_d1, segment_d0 : STD_LOGIC;
  signal d0, d1 : STD_LOGIC;
begin
  clk_gen : process begin
    clk50mhz <= '0'; wait for CLK_PERIOD/2;
    clk50mhz <= '1'; wait for CLK_PERIOD/2;
  end process;

  divider : entity work.mod50k_sync
    port map (clk => clk50mhz, clk_mod50k => clk_mod50k);

  dut : entity work.n_2_digit_bcd_7seg_decoder
    port map (current_bcd_d1 => current_bcd_d1, current_bcd_d0 => current_bcd_d0,
              clk_1khz => clk_mod50k, clk50mhz => clk50mhz, segment_d3 => segment_d3, segment_d2 => segment_d2,
              segment_d1 => segment_d1, segment_d0 => segment_d0, d0 => d0, d1 => d1);

  checker : process
    constant NUM_PERIODS : integer := 12;
    variable t_rise_d0, t_fall_d0 : time;
    variable high_d0_ns, high_d1_ns, period_ns : integer;
    variable total_high_d0, total_high_d1, total_period : integer := 0;
    variable duty_d0, duty_d1 : real;
    constant TOLERANCE_PCT : real := 2.0;
    variable errors : integer := 0;
  begin
    wait until rising_edge(d0);
    t_rise_d0 := now;
    for i in 1 to NUM_PERIODS loop
      wait until falling_edge(d0);
      t_fall_d0 := now;
      wait until rising_edge(d0);
      period_ns   := (now - t_rise_d0) / 1 ns;
      high_d0_ns  := (t_fall_d0 - t_rise_d0) / 1 ns;
      high_d1_ns  := period_ns - high_d0_ns;
      total_high_d0 := total_high_d0 + high_d0_ns;
      total_high_d1 := total_high_d1 + high_d1_ns;
      total_period  := total_period + period_ns;
      report "NOTE: period " & integer'image(i) & ": d0_high=" & integer'image(high_d0_ns) &
             " ns, d1_high=" & integer'image(high_d1_ns) & " ns, period=" & integer'image(period_ns) & " ns" severity note;
      t_rise_d0 := now;
    end loop;

    duty_d0 := 100.0 * real(total_high_d0) / real(total_period);
    duty_d1 := 100.0 * real(total_high_d1) / real(total_period);
    report "NOTE: aggregate duty: d0=" & real'image(duty_d0) & "%, d1=" & real'image(duty_d1) & "%" severity note;

    if abs(duty_d0 - 50.0) > TOLERANCE_PCT then
      report "FAIL: d0 duty cycle " & real'image(duty_d0) & "% deviates from 50%" severity error;
      errors := errors + 1;
    end if;
    if abs(duty_d1 - 50.0) > TOLERANCE_PCT then
      report "FAIL: d1 duty cycle " & real'image(duty_d1) & "% deviates from 50%" severity error;
      errors := errors + 1;
    end if;
    if errors = 0 then
      report "PASS: d0/d1 duty cycle within tolerance of 50/50" severity note;
    end if;
    wait;
  end process;
end sim;
