-- ============================================================
-- Entity: top
-- One-digit test harness: 50 MHz -> divider -> BCD counter -> 7-seg
-- ============================================================
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity top is
  Port (
    clk   : in  STD_LOGIC;
    reset : in  STD_LOGIC;
    seg_a : out STD_LOGIC;
    seg_b : out STD_LOGIC;
    seg_c : out STD_LOGIC;
    seg_d : out STD_LOGIC;
    seg_e : out STD_LOGIC;
    seg_f : out STD_LOGIC;
    seg_g : out STD_LOGIC
  );
end top;

architecture Structural of top is

  component mod50m_sync
    Port ( clk : in STD_LOGIC; clk_mod50m : out STD_LOGIC );
  end component;

  component counter0_9
    Port ( last_output : in  STD_LOGIC;
           clk         : in  STD_LOGIC;
           reset       : in  STD_LOGIC;
           current_bcd : out STD_LOGIC_VECTOR(3 downto 0);
           limit_reach : out STD_LOGIC );
  end component;

  component hex_7seg
    Port ( in1_msb, in2, in3, in4_lsb : in  STD_LOGIC;
           a, b, c, d, e, f, g        : out STD_LOGIC );
  end component;

  signal tick  : STD_LOGIC;
  signal bcd   : STD_LOGIC_VECTOR(3 downto 0);
  signal carry : STD_LOGIC;

begin

  u_div : mod50m_sync
    port map ( clk => clk, clk_mod50m => tick );

  u_cnt : counter0_9
    port map ( last_output => tick,
               clk         => clk,
               reset       => reset,
               current_bcd => bcd,
               limit_reach => carry );

  u_seg : hex_7seg
    port map ( in1_msb => bcd(3), in2 => bcd(2),
               in3     => bcd(1), in4_lsb => bcd(0),
               a => seg_a, b => seg_b, c => seg_c, d => seg_d,
               e => seg_e, f => seg_f, g => seg_g );

end Structural;