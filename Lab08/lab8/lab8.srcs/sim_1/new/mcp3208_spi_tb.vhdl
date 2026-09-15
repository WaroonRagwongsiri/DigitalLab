-- ============================================================
-- Testbench: mcp3208_spi_tb
-- Drives mcp3208_spi against a small behavioral MCP3208 slave model
-- that reconstructs the 5-bit command from DIN (checked against the
-- expected "11110" = single-ended, channel 6) and drives DOUT with a
-- known 12-bit test value, MSB-first, one null bit after CS falls.
-- Verifies data_out/data_valid for several test values, including
-- the 0 and 4095 (0xFFF) extremes.
-- ============================================================
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity mcp3208_spi_tb is
end mcp3208_spi_tb;

architecture sim of mcp3208_spi_tb is

  component mcp3208_spi
    Port (
      clk        : in  STD_LOGIC;
      start      : in  STD_LOGIC;
      SCK        : out STD_LOGIC;
      CS         : out STD_LOGIC;
      DIN        : out STD_LOGIC;
      DOUT       : in  STD_LOGIC;
      data_out   : out STD_LOGIC_VECTOR(11 downto 0);
      data_valid : out STD_LOGIC
    );
  end component;

  constant CLK_PERIOD : time := 20 ns; -- 50 MHz

  signal clk, start           : STD_LOGIC := '0';
  signal SCK, CS, DIN, DOUT   : STD_LOGIC := '0';
  signal data_out             : STD_LOGIC_VECTOR(11 downto 0);
  signal data_valid           : STD_LOGIC;
  signal stop_sim             : boolean := false;

  signal test_value : STD_LOGIC_VECTOR(11 downto 0) := (others => '0');

  type test_array is array (natural range <>) of integer;
  constant TEST_VALUES : test_array := (0, 4095, 1234, 6, 2048, 1);

begin

  uut : mcp3208_spi port map (
    clk        => clk,
    start      => start,
    SCK        => SCK,
    CS         => CS,
    DIN        => DIN,
    DOUT       => DOUT,
    data_out   => data_out,
    data_valid => data_valid
  );

  clk_gen : process
  begin
    while not stop_sim loop
      clk <= '0'; wait for CLK_PERIOD / 2;
      clk <= '1'; wait for CLK_PERIOD / 2;
    end loop;
    wait;
  end process;

  -- Behavioral MCP3208 slave model
  slave : process
    variable bit_cnt      : integer;
    variable cmd_captured : STD_LOGIC_VECTOR(4 downto 0);
    variable next_period  : integer;
  begin
    loop
      wait until CS = '0';
      bit_cnt      := 0;
      cmd_captured := (others => '0');
      DOUT         <= '0';

      while CS = '0' loop
        wait until rising_edge(SCK) or CS = '1';
        exit when CS = '1';

        if bit_cnt <= 4 then
          cmd_captured := cmd_captured(3 downto 0) & DIN;
        end if;

        next_period := bit_cnt + 1;
        if next_period = 5 then
          DOUT <= '0';
        elsif next_period >= 6 and next_period <= 17 then
          DOUT <= test_value(17 - next_period);
        end if;

        bit_cnt := bit_cnt + 1;
      end loop;

      if cmd_captured /= "11110" then
        report "SLAVE: bad command captured: " & to_string(cmd_captured) &
               " (expected 11110)" severity error;
      end if;
    end loop;
  end process;

  -- Stimulus + checker
  stimulus : process
    variable errors : natural := 0;
  begin
    wait until rising_edge(clk);

    for i in TEST_VALUES'range loop
      test_value <= STD_LOGIC_VECTOR(to_unsigned(TEST_VALUES(i), 12));
      wait until rising_edge(clk);

      start <= '1';
      wait until rising_edge(clk);
      start <= '0';

      wait until data_valid = '1';
      wait for 1 ns; -- let data_out settle in the same delta

      if to_integer(unsigned(data_out)) /= TEST_VALUES(i) then
        errors := errors + 1;
        report "MISMATCH: expected " & integer'image(TEST_VALUES(i)) &
               " got " & integer'image(to_integer(unsigned(data_out)))
               severity error;
      else
        report "OK: test_value=" & integer'image(TEST_VALUES(i)) &
               " -> data_out=" & integer'image(to_integer(unsigned(data_out)))
               severity note;
      end if;

      wait until rising_edge(clk);
      wait until rising_edge(clk);
    end loop;

    if errors = 0 then
      report "PASS: all " & integer'image(TEST_VALUES'length) &
             " mcp3208_spi conversions correct." severity note;
    else
      report integer'image(errors) & " mcp3208_spi mismatch(es) found." severity error;
    end if;

    stop_sim <= true;
    wait;
  end process;

end sim;
