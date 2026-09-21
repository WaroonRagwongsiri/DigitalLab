-- ============================================================
-- Entity: lab8_3
-- Multiplexes the 4-digit common-anode 7-segment display to show
-- the live LDR reading (MCP3208 channel 6) read over SPI.
-- Single clock domain (like เสือ/main.vhd): clk (50MHz) -> MOD_50 ->
-- clk_1mhz (~500kHz) drives both the ADC and the 7-segment digit mux,
-- so no clock-domain-crossing synchronizer is needed. BCD digits feed
-- the digit mux combinationally (same accepted "torn digit" trade-off
-- main.vhd's LCD path has -- self-corrects on the next scan pass).
-- Reuses the existing hex_7seg_decoder/hex_7seg BCD -> 7-segment path.
-- Target: AMD Spartan-7, clk = 50 MHz.
-- ============================================================
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity lab8_3 is
    Generic (
        ADC_CHANNEL : integer range 0 to 7 := 6  -- MCP3208 channel to sample (6 = onboard LDR)
    );
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

    signal clk_1mhz  : STD_LOGIC;                       -- shared clock for the ADC and digit mux

    signal start_adc    : STD_LOGIC := '1';
    signal is_adc_busy  : STD_LOGIC;
    signal adc_value     : STD_LOGIC_VECTOR(11 downto 0);

    signal bcd_thousands, bcd_hundreds, bcd_tens, bcd_ones : STD_LOGIC_VECTOR(3 downto 0);

    signal cur_bcd : STD_LOGIC_VECTOR(3 downto 0);     -- data_out from hex_7seg_decoder
    signal seg_a, seg_b, seg_c, seg_d, seg_e, seg_f, seg_g : STD_LOGIC;

    -- ~500kHz clk_1mhz / 500 -> 1kHz single-cycle trigger pulse for the digit mux
    signal trig_counter : integer range 0 to 499 := 0;
    signal trigger_1khz : STD_LOGIC := '0';

begin

    -- 50 MHz -> ~500 kHz shared clock for the ADC and digit-mux
    U_DIV : entity work.MOD_50
        port map (
            CLK     => clk,
            RST     => '0',
            CLK_OUT => clk_1mhz
        );

    -- Free-run the ADC: re-assert start_adc as soon as the previous conversion's busy flag deasserts
    process(clk_1mhz)
    begin
        if rising_edge(clk_1mhz) then
            if start_adc = '1' then
                if is_adc_busy = '1' then
                    start_adc <= '0';
                end if;
            elsif is_adc_busy = '0' then
                start_adc <= '1';
            end if;
        end if;
    end process;

    -- SPI/FSM ADC core, channel selected by ADC_CHANNEL generic (default 6 = LDR)
    U_ADC : entity work.ADC_MCP3208
        port map (
            RST            => '0',
            START          => start_adc,
            SGL_MODE       => '1',
            CHANNEL_SELECT => std_logic_vector(to_unsigned(ADC_CHANNEL, 3)),
            DATA_OUT       => adc_value,
            IS_BUSY        => is_adc_busy,
            ADC_CLK        => SCK,
            ADC_CS         => CS,
            ADC_MOSI       => DIN,
            ADC_MISO       => DOUT,
            CLK_1MHz       => clk_1mhz
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

    -- 1 kHz single-cycle trigger pulse, derived from clk_1mhz (no longer
    -- needs the real 50MHz clk)
    process(clk_1mhz)
    begin
        if rising_edge(clk_1mhz) then
            if trig_counter = 499 then
                trig_counter <= 0;
                trigger_1khz <= '1';
            else
                trig_counter <= trig_counter + 1;
                trigger_1khz <= '0';
            end if;
        end if;
    end process;

    -- Digit-select counter, clocked by clk_1mhz, advances one digit per
    -- 1kHz trigger pulse
    U_SEL : entity work.hex_7seg_decoder
        port map (
            clk      => clk_1mhz,
            trigger  => trigger_1khz,
            d3_data  => bcd_thousands,
            d2_data  => bcd_hundreds,
            d1_data  => bcd_tens,
            d0_data  => bcd_ones,
            data_out => cur_bcd,
            d3       => digit(3),
            d2       => digit(2),
            d1       => digit(1),
            d0       => digit(0)
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
