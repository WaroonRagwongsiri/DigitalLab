-- ============================================================
-- Entity: ldr_led_test
-- Minimal hardware/software isolation test for the LDR/ADC path.
-- Bypasses bin2bcd12 / hex_7seg_decoder / hex_7seg entirely and
-- drives the 12-bit MCP3208 channel 6 (LDR) reading straight onto
-- 12 LEDs, exactly like the original "Chapter 7b" reference demo.
-- Reuses mod50k_sync, mod100_sync and mcp3208_spi unmodified.
--
-- Set this as the top module (temporarily, in place of lab8_3) to
-- check whether the ADC reading itself changes when you cover/
-- uncover the LDR -- with the display pipeline fully out of the
-- picture. Requires the J4 and J9 LED-enable jumpers already in
-- place.
-- ============================================================
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity ldr_led_test is
    Port (
        clk  : in  STD_LOGIC;
        led  : out STD_LOGIC_VECTOR(11 downto 0);
        SCK  : out STD_LOGIC;
        CS   : out STD_LOGIC;
        DIN  : out STD_LOGIC;
        DOUT : in  STD_LOGIC
    );
end ldr_led_test;

architecture Behavioral of ldr_led_test is

    signal clk_1khz      : STD_LOGIC;
    signal sample_trigger : STD_LOGIC;
    signal adc_value      : STD_LOGIC_VECTOR(11 downto 0);
    signal adc_valid      : STD_LOGIC;

    -- Flag these nets for the Set Up Debug wizard to auto-probe with an ILA
    attribute mark_debug : string;
    attribute mark_debug of SCK            : signal is "true";
    attribute mark_debug of CS             : signal is "true";
    attribute mark_debug of DIN            : signal is "true";
    attribute mark_debug of DOUT           : signal is "true";
    attribute mark_debug of adc_value      : signal is "true";
    attribute mark_debug of adc_valid      : signal is "true";
    attribute mark_debug of sample_trigger : signal is "true";

begin

    U_DIV : entity work.mod50k_sync
        port map (
            clk        => clk,
            mod50k_out => clk_1khz
        );

    U_DIV100 : entity work.mod100_sync
        port map (
            trigger    => clk_1khz,
            clk        => clk,
            mod100_out => sample_trigger
        );

    U_ADC : entity work.mcp3208_spi
        port map (
            clk        => clk,
            start      => sample_trigger,
            SCK        => SCK,
            CS         => CS,
            DIN        => DIN,
            DOUT       => DOUT,
            data_out   => adc_value,
            data_valid => adc_valid
        );

    led <= adc_value;

end Behavioral;
