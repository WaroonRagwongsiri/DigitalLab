-- ============================================================
-- Testbench: lab8_3_tb
-- Drives lab8_3's SPI pins (SCK/CS/DIN/DOUT) against a behavioral
-- MCP3208 slave model (reconstructs the 5-bit command from DIN and
-- checks it against the expected "11110" = single-ended, channel 6;
-- drives DOUT with a programmable 12-bit test value), and verifies
-- the 4-digit display shows the correct decimal digits after each
-- simulated ADC reading, with no overlapping digit-enable lines.
-- Two phases are run: test_value=1234 (multi-digit) then test_value=6
-- (single-digit, exercises leading-zero digits on the display).
-- Reuses this session's overlap/dwell-checking monitor style from the
-- earlier fixed-"1234" testbench, generalized to a dynamic expected
-- value driven from outside lab8_3 (CS's rising edge is the only
-- externally-visible signal of "a conversion just finished").
-- ============================================================
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity lab8_3_tb is
end lab8_3_tb;

architecture sim of lab8_3_tb is

  component lab8_3
    Port (
      clk           : in  STD_LOGIC;
      digit         : out STD_LOGIC_VECTOR(3 downto 0);
      Seven_Segment : out STD_LOGIC_VECTOR(7 downto 0);
      SCK           : out STD_LOGIC;
      CS            : out STD_LOGIC;
      DIN           : out STD_LOGIC;
      DOUT          : in  STD_LOGIC
    );
  end component;

  constant CLK_PERIOD   : time    := 20 ns;  -- 50 MHz
  constant SWEEP_CYCLES : natural := 4 * 50000;  -- one full 4-digit refresh
  constant MIN_DWELL_CYCLES : natural := 5000;   -- 10% of the expected ~50,000-cycle dwell

  signal clk           : STD_LOGIC := '0';
  signal digit         : STD_LOGIC_VECTOR(3 downto 0);
  signal Seven_Segment : STD_LOGIC_VECTOR(7 downto 0);
  signal SCK, CS, DIN  : STD_LOGIC;
  signal DOUT          : STD_LOGIC := '0';
  signal stop_sim      : boolean := false;

  signal test_value       : STD_LOGIC_VECTOR(11 downto 0) := (others => '0');
  signal expected_value   : integer := 0;
  signal checking_enabled : boolean := false;

  -- inverse of hex_7seg's truth table: segments (a,b,c,d,e,f,g active-low)
  -- -> decoded 0-9, or -1 if not one of the driven codes (blank/invalid).
  function decode_segments(seg : STD_LOGIC_VECTOR(6 downto 0)) return integer is
  begin
    case seg is
      when "0000001" => return 0;
      when "1001111" => return 1;
      when "0010010" => return 2;
      when "0000110" => return 3;
      when "1001100" => return 4;
      when "0100100" => return 5;
      when "0100000" => return 6;
      when "0001111" => return 7;
      when "0000000" => return 8;
      when "0000100" => return 9;
      when others     => return -1;
    end case;
  end function;

  -- hex_7seg_decoder's d3/d2/d1/d0 outputs are one-hot ACTIVE-HIGH (exactly
  -- one of d3..d0 = '1' when a digit is selected; confirmed by reading its
  -- truth table: d3<=n1_qn and n2_qn, etc. -- a one-hot-high decode of the
  -- internal 2-bit counter). digit(i) <= d_i directly (no inversion).
  -- BUT the internal data mux cross-wires the select and data indices:
  -- d3_data is gated by n9_o (the SAME term that drives output d0), and
  -- d0_data is gated by n6_o (the same term that drives output d3) -- so
  -- digit(3)='1' shows d0_data, digit(0)='1' shows d3_data, etc. This
  -- makes bcd3(thousands) appear on the digit(0)-selected physical slot,
  -- which the XDC labels the *leftmost* position -- i.e. the leftmost
  -- physical digit correctly shows the most-significant decimal digit.
  -- which_digit(d) below returns the *select bit index* (0..3), which a
  -- caller must convert to a decimal place via (3 - index).
  function which_digit(d : STD_LOGIC_VECTOR(3 downto 0)) return integer is
  begin
    if    d = "0001" then return 0;
    elsif d = "0010" then return 1;
    elsif d = "0100" then return 2;
    elsif d = "1000" then return 3;
    else return -1;
    end if;
  end function;

  function count_high(d : STD_LOGIC_VECTOR(3 downto 0)) return natural is
    variable n : natural := 0;
  begin
    for i in d'range loop
      if d(i) = '1' then
        n := n + 1;
      end if;
    end loop;
    return n;
  end function;

  -- decimal digit of `v` at `place` (0=ones,1=tens,2=hundreds,3=thousands)
  function digit_at(v : integer; place : integer) return integer is
  begin
    case place is
      when 0 => return v mod 10;
      when 1 => return (v / 10) mod 10;
      when 2 => return (v / 100) mod 10;
      when others => return (v / 1000) mod 10;
    end case;
  end function;

begin

  uut : lab8_3 port map (
    clk           => clk,
    digit         => digit,
    Seven_Segment => Seven_Segment,
    SCK           => SCK,
    CS            => CS,
    DIN           => DIN,
    DOUT          => DOUT
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

  monitor : process
    variable errors       : natural := 0;
    variable warnings     : natural := 0;
    variable num_high      : natural;
    variable active_digit : integer := -1;
    variable prev_digit   : integer := -1;
    variable dwell_cycles : natural := 0;
    variable seg_val      : integer;
    variable cycle        : natural := 0;
  begin
    wait until rising_edge(clk);

    loop
      wait until rising_edge(clk);
      exit when stop_sim;
      cycle := cycle + 1;

      num_high := count_high(digit);

      if num_high > 1 then
        errors := errors + 1;
        report "OVERLAP at cycle " & integer'image(cycle) &
               " (t=" & time'image(now) & "): digit=" & to_string(digit)
               severity error;
        active_digit := -1;

      elsif num_high = 1 then
        active_digit := which_digit(digit);

        if active_digit /= prev_digit then
          if prev_digit /= -1 and checking_enabled and dwell_cycles < MIN_DWELL_CYCLES then
            warnings := warnings + 1;
            report "WARNING: digit" & integer'image(prev_digit) &
                   " only stayed active for " & integer'image(dwell_cycles) &
                   " clk cycles (expected ~50000)" severity note;
          end if;
          dwell_cycles := 0;
        end if;
        dwell_cycles := dwell_cycles + 1;

        if checking_enabled and active_digit >= 0 then
          seg_val := decode_segments(Seven_Segment(7 downto 1));
          if seg_val /= digit_at(expected_value, 3 - active_digit) then
            errors := errors + 1;
            report "MISMATCH at cycle " & integer'image(cycle) &
                   ": digit(select bit)=" & integer'image(active_digit) &
                   " expected=" & integer'image(digit_at(expected_value, 3 - active_digit)) &
                   " but Seven_Segment decodes to " & integer'image(seg_val)
                   severity error;
          end if;
        end if;

        prev_digit := active_digit;

      else
        active_digit := -1;
      end if;
    end loop;

    if errors = 0 then
      report "PASS: no overlap, no mismatches (" & integer'image(warnings) &
             " dwell warning(s))." severity note;
    else
      report integer'image(errors) & " error(s) found (" &
             integer'image(warnings) & " dwell warning(s))." severity error;
    end if;
    wait;
  end process;

  stimulus : process
  begin
    wait until rising_edge(clk);

    -- Phase 1: multi-digit value 1234
    test_value <= STD_LOGIC_VECTOR(to_unsigned(1234, 12));
    report "Phase 1: waiting for first ADC conversion (test_value=1234)..." severity note;
    wait until rising_edge(CS);           -- first SPI transaction just finished
    wait for 10 * CLK_PERIOD;             -- margin for data_valid + display-latch propagation
    expected_value   <= 1234;
    checking_enabled <= true;
    wait for SWEEP_CYCLES * CLK_PERIOD;   -- one full digit-refresh sweep
    checking_enabled <= false;
    report "Phase 1 done." severity note;

    -- Phase 2: single-digit value 6 (exercises leading zeros: "0006")
    test_value <= STD_LOGIC_VECTOR(to_unsigned(6, 12));
    report "Phase 2: waiting for second ADC conversion (test_value=6)..." severity note;
    wait until rising_edge(CS);
    wait for 10 * CLK_PERIOD;
    expected_value   <= 6;
    checking_enabled <= true;
    wait for SWEEP_CYCLES * CLK_PERIOD;
    checking_enabled <= false;
    report "Phase 2 done." severity note;

    stop_sim <= true;
    wait;
  end process;

end sim;
