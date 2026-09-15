-- ============================================================
-- Entity: mod100_sync
-- Divides an input pulse train by 100, following the same
-- cascaded-mod10_sync style as mod50k_sync's own /50000 chain.
-- Intended use: clk_1khz (1 kHz, already a clean 1-cycle pulse)
-- fed directly into `trigger` -> 1kHz/100 = 10 Hz mod100_out pulse.
-- ============================================================
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity mod100_sync is
  Port (
    trigger    : in  STD_LOGIC;
    clk        : in  STD_LOGIC;
    mod100_out : out STD_LOGIC
  );
end mod100_sync;

architecture Behavioral of mod100_sync is
  component mod10_sync
    Port (
      trigger : in  STD_LOGIC;
      clk : in  STD_LOGIC;
      mod10_out : out STD_LOGIC
    );
  end component;
  signal n1_mod10_out : STD_LOGIC;
begin

  u_0 : mod10_sync port map (
    trigger   => trigger,
    clk       => clk,
    mod10_out => n1_mod10_out
  );
  u_1 : mod10_sync port map (
    trigger   => n1_mod10_out,
    clk       => clk,
    mod10_out => mod100_out
  );

end Behavioral;
