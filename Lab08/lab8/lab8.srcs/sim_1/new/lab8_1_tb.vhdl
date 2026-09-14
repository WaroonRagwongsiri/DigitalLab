-- ============================================================
-- Testbench: lab8_1_tb
-- ============================================================
-- Checks that lab8_1 pulses `e` sixteen times, in order, with the
-- correct rs/data for each of the 5 init commands plus the 11
-- characters of "Hello World". lab8_1 now holds trigger_chain(0) off
-- for a ~20ms mod2/mod5 boot wait before the first send, so WAIT_LIMIT
-- must cover that once (every later send is only mod32_sync-scale).
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity lab8_1_tb is
end lab8_1_tb;

architecture sim of lab8_1_tb is

  component lab8_1
    Port (
      clk  : in  STD_LOGIC;
      e    : out STD_LOGIC;
      data : out STD_LOGIC_VECTOR(7 downto 0);
      rs   : out STD_LOGIC
    );
  end component;

  constant CLK_PERIOD : time := 20 ns;  -- 50 MHz
  constant WAIT_LIMIT  : time := 30 ms; -- covers the ~20ms boot wait plus margin

  signal clk  : STD_LOGIC := '0';
  signal e    : STD_LOGIC;
  signal data : STD_LOGIC_VECTOR(7 downto 0);
  signal rs   : STD_LOGIC;

  constant EXPECTED_COUNT : natural := 16;
  type byte_array is array (0 to EXPECTED_COUNT - 1) of STD_LOGIC_VECTOR(7 downto 0);

  constant EXPECTED_BYTES : byte_array := (
    x"38", x"0C", x"06", x"01", x"80",
    x"48", x"65", x"6C", x"6C", x"6F",
    x"20",
    x"57", x"6F", x"72", x"6C", x"64"
  );
  constant EXPECTED_RS : STD_LOGIC_VECTOR(0 to EXPECTED_COUNT - 1) := (
    '0', '0', '0', '0', '0',
    '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1'
  );

  function sl_char(v : STD_LOGIC) return character is
  begin
    if v = '1' then return '1'; else return '0'; end if;
  end function;

  function to_hex_char(nibble : STD_LOGIC_VECTOR(3 downto 0)) return character is
  begin
    case nibble is
      when "0000" => return '0'; when "0001" => return '1';
      when "0010" => return '2'; when "0011" => return '3';
      when "0100" => return '4'; when "0101" => return '5';
      when "0110" => return '6'; when "0111" => return '7';
      when "1000" => return '8'; when "1001" => return '9';
      when "1010" => return 'A'; when "1011" => return 'B';
      when "1100" => return 'C'; when "1101" => return 'D';
      when "1110" => return 'E'; when others => return 'F';
    end case;
  end function;

  function to_hex_string(v : STD_LOGIC_VECTOR(7 downto 0)) return string is
  begin
    return to_hex_char(v(7 downto 4)) & to_hex_char(v(3 downto 0));
  end function;

begin

  uut : lab8_1 port map (
    clk  => clk,
    e    => e,
    data => data,
    rs   => rs
  );

  clk_gen : process
  begin
    clk <= '0'; wait for CLK_PERIOD / 2;
    clk <= '1'; wait for CLK_PERIOD / 2;
  end process;

  check : process
    variable errors : natural := 0;
  begin
    for i in 0 to EXPECTED_COUNT - 1 loop

      wait until (e = '1') for WAIT_LIMIT;
      if e /= '1' then
        report "TIMEOUT waiting for send #" & integer'image(i) &
               " - 'e' never went high (design stalled after " &
               integer'image(i) & " of " & integer'image(EXPECTED_COUNT) &
               " sends)" severity failure;
        exit;
      end if;

      if data = EXPECTED_BYTES(i) and rs = EXPECTED_RS(i) then
        report "send #" & integer'image(i) & " OK  (rs=" & sl_char(rs) &
               " data=0x" & to_hex_string(data) & ") at " & time'image(now);
      else
        errors := errors + 1;
        report "send #" & integer'image(i) & " MISMATCH: expected rs=" &
               sl_char(EXPECTED_RS(i)) & " data=0x" & to_hex_string(EXPECTED_BYTES(i)) &
               ", got rs=" & sl_char(rs) & " data=0x" & to_hex_string(data)
               severity error;
      end if;

      wait until (e = '0') for WAIT_LIMIT;
      if e /= '0' then
        report "TIMEOUT: send #" & integer'image(i) &
               " - 'e' never went back low" severity failure;
        exit;
      end if;

    end loop;

    if errors = 0 then
      report "ALL 16 SENDS CORRECT - data stream matches the ""Hello World"" init sequence." severity note;
    else
      report integer'image(errors) & " send(s) did not match the expected sequence." severity error;
    end if;

    wait;
  end process;

end sim;
