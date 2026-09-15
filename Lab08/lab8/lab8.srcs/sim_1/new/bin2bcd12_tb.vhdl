-- ============================================================
-- Testbench: bin2bcd12_tb
-- Purely combinational checks of bin2bcd12 against known values:
-- 0 -> 0000, 4095 -> 4095 (max 12-bit input), 1234 -> 1234,
-- 6 -> 0006 (the single-digit LDR-reading case).
-- ============================================================
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity bin2bcd12_tb is
end bin2bcd12_tb;

architecture sim of bin2bcd12_tb is

  component bin2bcd12
    Port (
      bin_in        : in  STD_LOGIC_VECTOR(11 downto 0);
      bcd_thousands : out STD_LOGIC_VECTOR(3 downto 0);
      bcd_hundreds  : out STD_LOGIC_VECTOR(3 downto 0);
      bcd_tens      : out STD_LOGIC_VECTOR(3 downto 0);
      bcd_ones      : out STD_LOGIC_VECTOR(3 downto 0)
    );
  end component;

  signal bin_in : STD_LOGIC_VECTOR(11 downto 0);
  signal th, hu, te, ones_sig : STD_LOGIC_VECTOR(3 downto 0);

  type case_t is record
    value : integer;
    th, hu, te, ones_v : integer;
  end record;
  type case_array is array (natural range <>) of case_t;
  constant CASES : case_array := (
    (0,    0,0,0,0),
    (4095, 4,0,9,5),
    (1234, 1,2,3,4),
    (6,    0,0,0,6),
    (9,    0,0,0,9),
    (10,   0,0,1,0),
    (999,  0,9,9,9),
    (4096-1, 4,0,9,5)  -- redundant re-check of the max value
  );

begin

  uut : bin2bcd12 port map (
    bin_in        => bin_in,
    bcd_thousands => th,
    bcd_hundreds  => hu,
    bcd_tens      => te,
    bcd_ones      => ones_sig
  );

  process
    variable errors : natural := 0;
  begin
    for i in CASES'range loop
      bin_in <= STD_LOGIC_VECTOR(to_unsigned(CASES(i).value, 12));
      wait for 10 ns;

      if to_integer(unsigned(th)) /= CASES(i).th or
         to_integer(unsigned(hu)) /= CASES(i).hu or
         to_integer(unsigned(te)) /= CASES(i).te or
         to_integer(unsigned(ones_sig)) /= CASES(i).ones_v then
        errors := errors + 1;
        report "MISMATCH for bin_in=" & integer'image(CASES(i).value) &
               ": got " & integer'image(to_integer(unsigned(th))) &
               integer'image(to_integer(unsigned(hu))) &
               integer'image(to_integer(unsigned(te))) &
               integer'image(to_integer(unsigned(ones_sig))) &
               " expected " & integer'image(CASES(i).th) &
               integer'image(CASES(i).hu) &
               integer'image(CASES(i).te) &
               integer'image(CASES(i).ones_v)
               severity error;
      end if;
    end loop;

    if errors = 0 then
      report "PASS: all " & integer'image(CASES'length) & " bin2bcd12 cases correct." severity note;
    else
      report integer'image(errors) & " bin2bcd12 mismatch(es) found." severity error;
    end if;

    wait;
  end process;

end sim;
