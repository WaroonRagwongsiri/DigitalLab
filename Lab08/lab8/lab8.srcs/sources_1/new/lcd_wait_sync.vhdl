library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Free-running power-on wait: clk -> 6x (mod2_sync -> mod5_sync), i.e.
-- divide by 10^6 = 1,000,000 clocks. At 50 MHz (20 ns/clock) that's 20 ms,
-- comfortably above the HD44780's >=15ms power-on wait floor. First stage's
-- enable is tied to '1' so it counts continuously from power-on; wait_done
-- then pulses every 20 ms forever (initializer latches only the first one).
entity lcd_wait_sync is
  Port (
    clk       : in  STD_LOGIC;
    wait_done : out STD_LOGIC
  );
end lcd_wait_sync;

architecture Behavioral of lcd_wait_sync is
  component mod2_sync
    Port (
      last_output : in  STD_LOGIC;
      clk         : in  STD_LOGIC;
      mod2_out    : out STD_LOGIC
    );
  end component;
  component mod5_sync
    Port (
      last_output : in  STD_LOGIC;
      clk         : in  STD_LOGIC;
      mod5_out    : out STD_LOGIC
    );
  end component;

  constant ALWAYS_ON : STD_LOGIC := '1';
  signal n1, n2, n3, n4, n5, n6, n7, n8, n9, n10, n11, n12 : STD_LOGIC;
begin

  stage_1_div2 : mod2_sync port map (last_output => ALWAYS_ON, clk => clk, mod2_out => n1);
  stage_1_div5 : mod5_sync port map (last_output => n1,        clk => clk, mod5_out => n2);

  stage_2_div2 : mod2_sync port map (last_output => n2, clk => clk, mod2_out => n3);
  stage_2_div5 : mod5_sync port map (last_output => n3, clk => clk, mod5_out => n4);

  stage_3_div2 : mod2_sync port map (last_output => n4, clk => clk, mod2_out => n5);
  stage_3_div5 : mod5_sync port map (last_output => n5, clk => clk, mod5_out => n6);

  stage_4_div2 : mod2_sync port map (last_output => n6, clk => clk, mod2_out => n7);
  stage_4_div5 : mod5_sync port map (last_output => n7, clk => clk, mod5_out => n8);

  stage_5_div2 : mod2_sync port map (last_output => n8, clk => clk, mod2_out => n9);
  stage_5_div5 : mod5_sync port map (last_output => n9, clk => clk, mod5_out => n10);

  stage_6_div2 : mod2_sync port map (last_output => n10, clk => clk, mod2_out => n11);
  stage_6_div5 : mod5_sync port map (last_output => n11, clk => clk, mod5_out => n12);

  wait_done <= n12;

end Behavioral;
