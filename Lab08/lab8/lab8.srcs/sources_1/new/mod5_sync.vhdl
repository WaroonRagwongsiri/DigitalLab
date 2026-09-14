library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Divide-by-5, same "last_output"-gated pulse idiom as mod2_sync: counts
-- while last_output='1' and pulses mod5_out on the 5th such cycle.
entity mod5_sync is
  Port (
    last_output : in  STD_LOGIC;
    clk         : in  STD_LOGIC;
    mod5_out    : out STD_LOGIC
  );
end mod5_sync;

architecture Behavioral of mod5_sync is
  signal count : natural range 0 to 4 := 0;
begin

  process(clk)
  begin
    if rising_edge(clk) then
      if last_output = '1' then
        if count = 4 then
          count <= 0;
        else
          count <= count + 1;
        end if;
      end if;
    end if;
  end process;

  mod5_out <= '1' when (last_output = '1' and count = 4) else '0';

end Behavioral;
