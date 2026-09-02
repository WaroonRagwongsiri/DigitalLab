----------------------------------------------------------------------------
-- top.vhdl
--
-- Top level for a Spartan-7 board: debounced center pushbutton toggles a
-- status LED on/off. Port names match the provided XDC constraints:
--
--   clk           -> H11  (50 MHz system clock)
--   led_status    -> M1   (status LED)
--   toggle_switch -> J12  (center pushbutton, external PULLDOWN so idle='0')
--
-- Requires debounce_toggle.vhdl to be compiled into the same library.
-- No rst_n signal is needed: debounce_toggle generates its own one-cycle
-- power-on reset internally.
----------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity top is
    port (
        clk           : in  std_logic;
        toggle_switch : in  std_logic;
        led_status    : out std_logic
    );
end entity top;

architecture rtl of top is

    component debounce_toggle is
        port (
            clk           : in  std_logic;
            sw_in         : in  std_logic;
            toggle_output : out std_logic
        );
    end component;

begin

    u_debounce_toggle : debounce_toggle
        port map (
            clk           => clk,
            sw_in         => toggle_switch,
            toggle_output => led_status
        );

end architecture rtl;