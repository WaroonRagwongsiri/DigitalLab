-- ============================================================
-- Entity: hex_7seg
-- BCD digit (0-9) -> common-anode 7-segment decoder.
-- ============================================================
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity hex_7seg is
  Port (
    in1_msb : in  STD_LOGIC;
    in2 : in  STD_LOGIC;
    in3 : in  STD_LOGIC;
    in4_lsb : in  STD_LOGIC;
    a : out STD_LOGIC;
    b : out STD_LOGIC;
    c : out STD_LOGIC;
    d : out STD_LOGIC;
    e : out STD_LOGIC;
    f : out STD_LOGIC;
    g : out STD_LOGIC
  );
end hex_7seg;

architecture Behavioral of hex_7seg is

  signal nibble : STD_LOGIC_VECTOR(3 downto 0);
  signal seg    : STD_LOGIC_VECTOR(6 downto 0); -- a,b,c,d,e,f,g (active-low)

begin

  nibble <= in1_msb & in2 & in3 & in4_lsb;

  -- Segment truth table (active-low, common-anode). Bit order a,b,c,d,e,f,g.
  --   0: abcdef-   1: -bc----   2: ab-de-g   3: abcd--g   4: -bc--fg
  --   5: a-cd-fg   6: a-cdefg   7: abc----   8: abcdefg   9: abcd-fg
  with nibble select
    seg <= "0000001" when "0000",  -- 0
           "1001111" when "0001",  -- 1
           "0010010" when "0010",  -- 2
           "0000110" when "0011",  -- 3
           "1001100" when "0100",  -- 4
           "0100100" when "0101",  -- 5
           "0100000" when "0110",  -- 6
           "0001111" when "0111",  -- 7
           "0000000" when "1000",  -- 8
           "0000100" when "1001",  -- 9
           "1111111" when others;  -- not valid BCD (10-15): blank digit

  a <= seg(6);
  b <= seg(5);
  c <= seg(4);
  d <= seg(3);
  e <= seg(2);
  f <= seg(1);
  g <= seg(0);

end Behavioral;
