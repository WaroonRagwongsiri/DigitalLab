library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tb_start_stop_controller is
end tb_start_stop_controller;

architecture sim of tb_start_stop_controller is
  signal target_bcd    : STD_LOGIC_VECTOR(7 downto 0);
  signal toggle_output : STD_LOGIC;
  signal current_bcd   : STD_LOGIC_VECTOR(7 downto 0);
  signal start_flag    : STD_LOGIC;
  signal error_flag    : STD_LOGIC;
begin

  dut : entity work.start_stop_controller
    port map (
      target_bcd    => target_bcd,
      toggle_output => toggle_output,
      current_bcd   => current_bcd,
      start_flag    => start_flag,
      error_flag    => error_flag
    );

  stim : process
    variable errors : integer := 0;

    procedure check(
      tgt, cur  : STD_LOGIC_VECTOR(7 downto 0);
      tog       : STD_LOGIC;
      exp_err   : STD_LOGIC;
      exp_start : STD_LOGIC;
      label_    : string
    ) is
    begin
      target_bcd    <= tgt;
      current_bcd   <= cur;
      toggle_output <= tog;
      wait for 10 ns;
      if error_flag /= exp_err then
        report "FAIL: start_stop_controller [" & label_ & "] error_flag=" &
               STD_LOGIC'image(error_flag) & " expected " & STD_LOGIC'image(exp_err) severity error;
        errors := errors + 1;
      end if;
      if start_flag /= exp_start then
        report "FAIL: start_stop_controller [" & label_ & "] start_flag=" &
               STD_LOGIC'image(start_flag) & " expected " & STD_LOGIC'image(exp_start) severity error;
        errors := errors + 1;
      end if;
    end procedure;
  begin
    -- valid target, current well below target, running -> no error, start follows toggle
    check("00010010", "00000101", '1', '0', '1', "valid target, current<target, toggle=1");
    -- same, but toggle released -> start_flag must drop with it
    check("00010010", "00000101", '0', '0', '0', "valid target, toggle=0");
    -- invalid target: low nibble = 1010 (>9)
    check("00001010", "00000000", '1', '1', '0', "invalid low nibble target");
    -- invalid target: high nibble = 1010 (>9)
    check("10100000", "00000000", '1', '1', '0', "invalid high nibble target");
    -- current has already exceeded a valid target -> error per the raw compare
    check("00000101", "00010010", '1', '1', '0', "current greater than target");

    if errors = 0 then
      report "PASS: start_stop_controller error/start flags correct across the sweep" severity note;
    end if;
    wait;
  end process;

end sim;
