-- ============================================================
-- Entity: bcd_display_test
-- Isolation test for bin2bcd12 + the 7-segment display pipeline,
-- independent of the ADC/SPI path (mcp3208_spi). Feeds a constant
-- 12-bit value through bin2bcd12 and the same digit-mux chain used
-- by lab8_3, so the display should read a fixed "1234".
--
-- bin_in constant = "010011010010" = 1234 decimal (0x4D2):
--   thousands=1, hundreds=2, tens=3, ones=4.
--
-- Set this as the top module (temporarily, in place of lab8_3) to
-- check whether the display pipeline itself is correct while the
-- ADC read is still suspect (currently pegged/constant).
-- ============================================================
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity bcd_display_test is
    Port (
        clk           : in  STD_LOGIC;
        digit         : out STD_LOGIC_VECTOR(3 downto 0);
        Seven_Segment : out STD_LOGIC_VECTOR(7 downto 0)
    );
end bcd_display_test;

architecture Behavioral of bcd_display_test is

    constant TEST_VALUE : STD_LOGIC_VECTOR(11 downto 0) := "010011010010";  -- 1234

    signal clk_1khz : STD_LOGIC;
    signal cur_bcd   : STD_LOGIC_VECTOR(3 downto 0);

    signal bcd_thousands, bcd_hundreds, bcd_tens, bcd_ones : STD_LOGIC_VECTOR(3 downto 0);

    signal seg_a, seg_b, seg_c, seg_d, seg_e, seg_f, seg_g : STD_LOGIC;

begin

    -- 50 MHz -> 1 kHz digit-mux trigger (reused unmodified)
    U_DIV : entity work.mod50k_sync
        port map (
            clk        => clk,
            mod50k_out => clk_1khz
        );

    -- Fixed input straight into the binary -> BCD converter under test
    U_BCD : entity work.bin2bcd12
        port map (
            bin_in        => TEST_VALUE,
            bcd_thousands => bcd_thousands,
            bcd_hundreds  => bcd_hundreds,
            bcd_tens      => bcd_tens,
            bcd_ones      => bcd_ones
        );

    -- Real clk drives every flip-flop; clk_1khz is just an enable.
    U_SEL : entity work.hex_7seg_decoder
        port map (
            clk_50mhz   => clk,
            clk_trigger => clk_1khz,
            d3_data     => bcd_thousands,
            d2_data     => bcd_hundreds,
            d1_data     => bcd_tens,
            d0_data     => bcd_ones,
            data_out    => cur_bcd,
            d3          => digit(3),
            d2          => digit(2),
            d1          => digit(1),
            d0          => digit(0)
        );

    -- Reuse the existing BCD -> 7-segment decoder
    U_HEX : entity work.hex_7seg
        port map (
            in1_msb => cur_bcd(3),
            in2     => cur_bcd(2),
            in3     => cur_bcd(1),
            in4_lsb => cur_bcd(0),
            a => seg_a, b => seg_b, c => seg_c, d => seg_d,
            e => seg_e, f => seg_f, g => seg_g
        );

    -- Seven_Segment[7:0] = A,B,C,D,E,F,G,DP  (per your XDC)
    Seven_Segment(7) <= seg_a;
    Seven_Segment(6) <= seg_b;
    Seven_Segment(5) <= seg_c;
    Seven_Segment(4) <= seg_d;
    Seven_Segment(3) <= seg_e;
    Seven_Segment(2) <= seg_f;
    Seven_Segment(1) <= seg_g;
    Seven_Segment(0) <= '1';  -- decimal point off (active-low)

end Behavioral;
