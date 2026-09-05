library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tb_hex_7seg is
end tb_hex_7seg;

architecture sim of tb_hex_7seg is
  signal in1_msb, in2, in3, in4_lsb : STD_LOGIC;
  signal a, b, c, d, e, f, g        : STD_LOGIC;

  type seg_table_t is array (0 to 9) of STD_LOGIC_VECTOR(6 downto 0);
  -- bit order: a b c d e f g, standard active-high 7-segment digit shapes.
  -- If every digit comes out exactly bit-inverted from this table, that is
  -- itself diagnostic: the segments are active-low, not a logic bug.
  constant SEG_TABLE : seg_table_t := (
    0 => "1111110",
    1 => "0110000",
    2 => "1101101",
    3 => "1111001",
    4 => "0110011",
    5 => "1011011",
    6 => "1011111",
    7 => "1110000",
    8 => "1111111",
    9 => "1111011"
  );
begin

  dut : entity work.hex_7seg
    port map (
      in1_msb => in1_msb,
      in2     => in2,
      in3     => in3,
      in4_lsb => in4_lsb,
      a => a, b => b, c => c, d => d, e => e, f => f, g => g
    );

  stim : process
    variable errors : integer := 0;
    variable nibble  : STD_LOGIC_VECTOR(3 downto 0);
    variable got     : STD_LOGIC_VECTOR(6 downto 0);
  begin
    for digit in 0 to 9 loop
      nibble := std_logic_vector(to_unsigned(digit, 4));
      in1_msb <= nibble(3);
      in2     <= nibble(2);
      in3     <= nibble(1);
      in4_lsb <= nibble(0);
      wait for 10 ns;
      got := a & b & c & d & e & f & g;
      if got /= SEG_TABLE(digit) then
        if got = not SEG_TABLE(digit) then
          report "FAIL: hex_7seg digit " & integer'image(digit) &
                 " is exactly bit-inverted from the standard table (active-low segments?)" severity error;
        else
          report "FAIL: hex_7seg digit " & integer'image(digit) & " segments mismatch" severity error;
        end if;
        errors := errors + 1;
      end if;
    end loop;

    if errors = 0 then
      report "PASS: hex_7seg matches the standard active-high 7-segment table for digits 0-9" severity note;
    end if;
    wait;
  end process;

end sim;
