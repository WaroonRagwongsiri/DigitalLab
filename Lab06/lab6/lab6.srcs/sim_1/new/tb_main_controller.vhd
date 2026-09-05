library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tb_main_controller is
end tb_main_controller;

architecture sim of tb_main_controller is
  constant CLK_PERIOD : time := 20 ns; -- true 50 MHz

  signal clk50mhz       : STD_LOGIC := '0';
  signal target_bcd     : STD_LOGIC_VECTOR(7 downto 0) := (others => '0');
  signal btn_start_stop : STD_LOGIC := '0';
  signal current_bcd_d1 : STD_LOGIC_VECTOR(3 downto 0);
  signal current_bcd_d0 : STD_LOGIC_VECTOR(3 downto 0);
  signal led_status     : STD_LOGIC;
begin

  dut : entity work.main_controller
    port map (
      clk50mhz       => clk50mhz,
      target_bcd     => target_bcd,
      btn_start_stop => btn_start_stop,
      current_bcd_d1 => current_bcd_d1,
      current_bcd_d0 => current_bcd_d0,
      led_status     => led_status
    );

  clk_gen : process
  begin
    clk50mhz <= '0';
    wait for CLK_PERIOD/2;
    clk50mhz <= '1';
    wait for CLK_PERIOD/2;
  end process;

  stim : process
    variable errors      : integer := 0;
    variable start_val   : STD_LOGIC_VECTOR(7 downto 0);
    variable seen_change : boolean;
  begin
    -- invalid target: low nibble = 1010 (>9) should raise led_status regardless of button
    target_bcd     <= "00001010";
    btn_start_stop <= '0';
    wait for 1 us;
    if led_status /= '1' then
      report "FAIL: main_controller led_status not asserted for invalid BCD target" severity error;
      errors := errors + 1;
    end if;

    -- switch to a valid target: error should clear
    target_bcd <= "00000101"; -- 5
    wait for 1 us;
    if led_status /= '0' then
      report "FAIL: main_controller led_status stuck asserted for a valid BCD target" severity error;
      errors := errors + 1;
    end if;

    -- a clean, held button press should validate through the debounce/toggle chain
    -- and start the counter without raising an error
    start_val := current_bcd_d1 & current_bcd_d0;
    btn_start_stop <= '1';
    wait for 2 ms;
    btn_start_stop <= '0';

    seen_change := false;
    for i in 0 to 4 loop
      wait for 60 ms;
      if (current_bcd_d1 & current_bcd_d0) /= start_val then
        seen_change := true;
      end if;
    end loop;

    if led_status /= '0' then
      report "FAIL: main_controller led_status asserted unexpectedly while running" severity error;
      errors := errors + 1;
    end if;
    if not seen_change then
      report "FAIL: main_controller current_bcd_d1/d0 never advanced after a validated start press" severity error;
      errors := errors + 1;
    else
      report "NOTE: main_controller advanced current_bcd_d1/d0 after start - compare the interval against " &
             "the intended 50 ms clk_20hz tick (see tb_lab6 for a precise measurement)" severity note;
    end if;

    if errors = 0 then
      report "PASS: main_controller error flag and start/count behavior correct" severity note;
    end if;
    wait;
  end process;

end sim;
