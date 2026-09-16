-- ============================================================
-- Entity: lab8_3
-- Multiplexes the 4-digit common-anode 7-segment display to show
-- the live LDR reading (MCP3208 channel 6) read over SPI.
-- Clocking chain: clk (50MHz) -> mod50k_sync -> clk_1khz enable pulse
--                 -> hex_7seg_decoder, clocked by the real clk with
--                    clk_1khz as a synchronous enable (single clock
--                    domain -- no generated/gated clock).
--                 clk_1khz -> mod100_sync -> sample_trigger (~10 Hz)
--                 -> mcp3208_spi (channel 6) -> adc_value/adc_valid
--                 -> bin2bcd12 (combinational) -> BCD digits, latched
--                    into bcd3..bcd0 on adc_valid so hex_7seg_decoder's
--                    combinational digit mux never sees a value torn
--                    mid-refresh-sweep by an in-flight bin2bcd12 update.
-- Reuses the existing hex_7seg BCD -> 7-segment decoder.
-- Target: AMD Spartan-7, clk = 50 MHz.
-- ============================================================
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity lab8_3 is
    Port (
        clk           : in  STD_LOGIC;
        digit         : out STD_LOGIC_VECTOR(3 downto 0);
        Seven_Segment : out STD_LOGIC_VECTOR(7 downto 0);
        SCK           : out STD_LOGIC;
        CS            : out STD_LOGIC;
        DIN           : out STD_LOGIC;
        DOUT          : in  STD_LOGIC
    );
end lab8_3;

architecture Behavioral of lab8_3 is

    signal clk_1khz  : STD_LOGIC;                       -- 1 kHz enable pulse
    signal cur_bcd   : STD_LOGIC_VECTOR(3 downto 0);     -- data_out from hex_7seg_decoder

    signal sample_trigger : STD_LOGIC;                  -- ~10 Hz ADC sample/display-refresh pulse
    signal adc_value       : STD_LOGIC_VECTOR(11 downto 0);
    signal adc_valid       : STD_LOGIC;

    signal bcd_thousands, bcd_hundreds, bcd_tens, bcd_ones : STD_LOGIC_VECTOR(3 downto 0);

    -- Digit values displayed, latched atomically from the ADC reading
    signal bcd0, bcd1, bcd2, bcd3 : STD_LOGIC_VECTOR(3 downto 0) := "0000";

    signal seg_a, seg_b, seg_c, seg_d, seg_e, seg_f, seg_g : STD_LOGIC;

begin

    -- 50 MHz -> 1 kHz enable pulse
    U_DIV : entity work.mod50k_sync
        port map (
            clk        => clk,
            mod50k_out => clk_1khz
        );

    -- 1 kHz -> ~10 Hz ADC sample / display-refresh trigger
    U_DIV100 : entity work.mod100_sync
        port map (
            trigger    => clk_1khz,
            clk        => clk,
            mod100_out => sample_trigger
        );

    -- SPI master for the MCP3208, channel 6 (LDR)
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

    -- Combinational binary -> 4-digit BCD conversion of the latest ADC reading
    U_BCD : entity work.bin2bcd12
        port map (
            bin_in        => adc_value,
            bcd_thousands => bcd_thousands,
            bcd_hundreds  => bcd_hundreds,
            bcd_tens      => bcd_tens,
            bcd_ones      => bcd_ones
        );

    -- Latch all 4 BCD digits atomically once per ADC sample
    process(clk)
    begin
        if rising_edge(clk) then
            if adc_valid = '1' then
                bcd3 <= bcd_thousands;
                bcd2 <= bcd_hundreds;
                bcd1 <= bcd_tens;
                bcd0 <= bcd_ones;
            end if;
        end if;
    end process;

    -- Real clk drives every flip-flop; clk_1khz is just an enable.
    -- Cycles 00->01->10->11, muxing out the active digit's data and
    -- its active-high enable line (board's DIGIT[3:0] select is
    -- active-high per the datasheet -- selected digit gets '1').
    U_SEL : entity work.hex_7seg_decoder
        port map (
            clk_50mhz   => clk,
            clk_trigger => clk_1khz,
            d3_data     => bcd3,
            d2_data     => bcd2,
            d1_data     => bcd1,
            d0_data     => bcd0,
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
