library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tb_concat4bit_8bit is
end tb_concat4bit_8bit;

architecture sim of tb_concat4bit_8bit is
  signal lhs, rhs : STD_LOGIC_VECTOR(3 downto 0);
  signal out8bit  : STD_LOGIC_VECTOR(7 downto 0);
begin

  dut : entity work.concat4bit_8bit
    port map (lhs => lhs, rhs => rhs, out8bit => out8bit);

  stim : process
    variable errors : integer := 0;

    type vec_pair is record
      l : STD_LOGIC_VECTOR(3 downto 0);
      r : STD_LOGIC_VECTOR(3 downto 0);
    end record;
    type vec_pair_array is array (natural range <>) of vec_pair;
    constant CASES : vec_pair_array := (
      ("0000", "0000"),
      ("1111", "1111"),
      ("1010", "0101"),
      ("0001", "1000"),
      ("1100", "0011")
    );
  begin
    for i in CASES'range loop
      lhs <= CASES(i).l;
      rhs <= CASES(i).r;
      wait for 10 ns;
      if out8bit /= (CASES(i).l & CASES(i).r) then
        report "FAIL: concat4bit_8bit case " & integer'image(i) & " mismatch" severity error;
        errors := errors + 1;
      end if;
    end loop;

    if errors = 0 then
      report "PASS: concat4bit_8bit concatenates lhs & rhs correctly" severity note;
    end if;
    wait;
  end process;

end sim;
