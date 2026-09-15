-- ============================================================
-- Entity: bin2bcd12
-- Combinational 12-bit binary -> 4-digit BCD converter using the
-- shift-add-3 ("double dabble") algorithm. 12 bit input covers the
-- MCP3208's full 0-4095 range, which keeps the thousands digit <=4
-- with no special-casing needed.
-- ============================================================
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity bin2bcd12 is
  Port (
    bin_in        : in  STD_LOGIC_VECTOR(11 downto 0);
    bcd_thousands : out STD_LOGIC_VECTOR(3 downto 0);
    bcd_hundreds  : out STD_LOGIC_VECTOR(3 downto 0);
    bcd_tens      : out STD_LOGIC_VECTOR(3 downto 0);
    bcd_ones      : out STD_LOGIC_VECTOR(3 downto 0)
  );
end bin2bcd12;

architecture Behavioral of bin2bcd12 is
begin

  process(bin_in)
    -- [ thousands(4) | hundreds(4) | tens(4) | ones(4) | binary(12) ]
    variable shreg : STD_LOGIC_VECTOR(27 downto 0);
  begin
    shreg             := (others => '0');
    shreg(11 downto 0) := bin_in;

    for i in 0 to 11 loop
      if unsigned(shreg(15 downto 12)) >= 5 then
        shreg(15 downto 12) := STD_LOGIC_VECTOR(unsigned(shreg(15 downto 12)) + 3);
      end if;
      if unsigned(shreg(19 downto 16)) >= 5 then
        shreg(19 downto 16) := STD_LOGIC_VECTOR(unsigned(shreg(19 downto 16)) + 3);
      end if;
      if unsigned(shreg(23 downto 20)) >= 5 then
        shreg(23 downto 20) := STD_LOGIC_VECTOR(unsigned(shreg(23 downto 20)) + 3);
      end if;
      if unsigned(shreg(27 downto 24)) >= 5 then
        shreg(27 downto 24) := STD_LOGIC_VECTOR(unsigned(shreg(27 downto 24)) + 3);
      end if;

      shreg := shreg(26 downto 0) & '0';
    end loop;

    bcd_ones      <= shreg(15 downto 12);
    bcd_tens      <= shreg(19 downto 16);
    bcd_hundreds  <= shreg(23 downto 20);
    bcd_thousands <= shreg(27 downto 24);
  end process;

end Behavioral;
