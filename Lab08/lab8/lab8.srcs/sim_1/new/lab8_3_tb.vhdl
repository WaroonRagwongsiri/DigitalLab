-- ============================================================
-- Testbench: lab8_3_tb
-- Traces `digit` / `Seven_Segment` over several full 4-digit refresh
-- sweeps to catch overlapping digit-enable lines or wrong decoded
-- values (should be a clean, static "1234": digit3=1 digit2=2
-- digit1=3 digit0=4). Independently re-derives the decoded value
-- from Seven_Segment using the inverse of hex_7seg's truth table,
-- rather than re-implementing lab8_3's internals.
-- ============================================================
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity lab8_3_tb is
end lab8_3_tb;

architecture sim of lab8_3_tb is

  component lab8_3
    Port (
      clk           : in  STD_LOGIC;
      digit         : out STD_LOGIC_VECTOR(3 downto 0);
      Seven_Segment : out STD_LOGIC_VECTOR(7 downto 0)
    );
  end component;

  constant CLK_PERIOD   : time    := 20 ns;  -- 50 MHz
  constant SWEEP_CYCLES : natural := 4 * 50000;      -- one full 4-digit refresh
  constant NUM_SWEEPS   : natural := 3;
  constant RUN_CYCLES   : natural := NUM_SWEEPS * SWEEP_CYCLES;

  -- a dwell shorter than this fraction of the expected ~50,000-cycle
  -- window is suspicious evidence of a double-advance (level-sensitive
  -- enable) bug in digit_selector's counter.
  constant MIN_DWELL_CYCLES : natural := 5000;  -- 10% of 50,000

  signal clk           : STD_LOGIC := '0';
  signal digit         : STD_LOGIC_VECTOR(3 downto 0);
  signal Seven_Segment : STD_LOGIC_VECTOR(7 downto 0);
  signal stop_sim      : boolean := false;

  -- expected fixed digit values: digit3=1 digit2=2 digit1=3 digit0=4
  type expected_array is array (0 to 3) of integer;
  constant EXPECTED_VALUE : expected_array := (0 => 4, 1 => 3, 2 => 2, 3 => 1);

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

  function which_digit(d : STD_LOGIC_VECTOR(3 downto 0)) return integer is
  begin
    if    d = "1110" then return 0;
    elsif d = "1101" then return 1;
    elsif d = "1011" then return 2;
    elsif d = "0111" then return 3;
    else return -1;
    end if;
  end function;

  function count_low(d : STD_LOGIC_VECTOR(3 downto 0)) return natural is
    variable n : natural := 0;
  begin
    for i in d'range loop
      if d(i) = '0' then
        n := n + 1;
      end if;
    end loop;
    return n;
  end function;

begin

  uut : lab8_3 port map (
    clk           => clk,
    digit         => digit,
    Seven_Segment => Seven_Segment
  );

  clk_gen : process
  begin
    while not stop_sim loop
      clk <= '0'; wait for CLK_PERIOD / 2;
      clk <= '1'; wait for CLK_PERIOD / 2;
    end loop;
    wait;
  end process;

  monitor : process
    variable errors        : natural := 0;
    variable warnings      : natural := 0;
    variable num_low       : natural;
    variable active_digit  : integer := -1;
    variable prev_digit    : integer := -1;
    variable dwell_cycles  : natural := 0;
    variable seg_val       : integer;
    variable last_val      : expected_array := (others => -1);
    variable cycle         : natural := 0;
    variable overlap_seen  : boolean := false;
  begin
    -- let the design's clk-domain reset settle for one edge before sampling
    wait until rising_edge(clk);

    for i in 0 to RUN_CYCLES - 1 loop
      wait until rising_edge(clk);
      cycle := cycle + 1;

      num_low := count_low(digit);

      if num_low > 1 then
        if not overlap_seen then
          report "OVERLAP at cycle " & integer'image(cycle) &
                 " (t=" & time'image(now) & "): digit=" & to_string(digit) &
                 " - more than one digit enable line active simultaneously"
                 severity error;
          overlap_seen := true;
        end if;
        errors := errors + 1;
        active_digit := -1;

      elsif num_low = 1 then
        active_digit := which_digit(digit);

        if active_digit /= prev_digit then
          -- digit changed (or first sample): check the dwell of the
          -- digit we just left, then reset the dwell counter.
          if prev_digit /= -1 and dwell_cycles < MIN_DWELL_CYCLES then
            warnings := warnings + 1;
            report "WARNING: digit" & integer'image(prev_digit) &
                   " only stayed active for " & integer'image(dwell_cycles) &
                   " clk cycles (expected ~50000) - possible double-advance" &
                   " of digit_selector's counter" severity note;
          end if;
          dwell_cycles := 0;
        end if;
        dwell_cycles := dwell_cycles + 1;

        seg_val := decode_segments(Seven_Segment(7 downto 1));

        if active_digit >= 0 then
          if seg_val /= EXPECTED_VALUE(active_digit) then
            errors := errors + 1;
            report "MISMATCH at cycle " & integer'image(cycle) &
                   ": digit" & integer'image(active_digit) &
                   " expected value=" & integer'image(EXPECTED_VALUE(active_digit)) &
                   " but Seven_Segment decodes to " & integer'image(seg_val)
                   severity error;
          else
            last_val(active_digit) := seg_val;
          end if;
        else
          errors := errors + 1;
          report "MISMATCH at cycle " & integer'image(cycle) &
                 ": digit=" & to_string(digit) &
                 " does not match any expected one-hot pattern" severity error;
        end if;

        prev_digit := active_digit;

      else
        -- num_low = 0: no digit enabled (blanking); not itself an error,
        -- but breaks the current dwell run.
        active_digit := -1;
      end if;

    end loop;

    report "Final decoded sweep: digit3=" & integer'image(last_val(3)) &
           " digit2=" & integer'image(last_val(2)) &
           " digit1=" & integer'image(last_val(1)) &
           " digit0=" & integer'image(last_val(0)) severity note;

    if errors = 0 then
      report "PASS: no overlap, no mismatches across " & integer'image(NUM_SWEEPS) &
             " full refresh sweeps (" & integer'image(warnings) &
             " dwell warning(s))." severity note;
    else
      report integer'image(errors) & " error(s) found (" &
             integer'image(warnings) & " dwell warning(s))." severity error;
    end if;

    stop_sim <= true;
    wait;
  end process;

end sim;
