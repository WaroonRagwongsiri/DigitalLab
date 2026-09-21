LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

USE work.LCD_MSG_TYPE.ALL;

ENTITY main IS
    PORT (
        clk : IN STD_LOGIC;
        sw : IN STD_LOGIC_VECTOR (15 DOWNTO 0);

        lcd_data : OUT STD_LOGIC_VECTOR (7 DOWNTO 0);
        lcd_e : OUT STD_LOGIC;
        lcd_rs : OUT STD_LOGIC;

        adc_sck : OUT STD_LOGIC;
        adc_cs : OUT STD_LOGIC;
        adc_mosi : OUT STD_LOGIC;
        adc_miso : IN STD_LOGIC
    );
END main;

ARCHITECTURE Behavioral OF main IS

    COMPONENT MOD_50
        PORT (
            CLK, RST : IN STD_LOGIC;
            CLK_OUT : OUT STD_LOGIC
        );
    END COMPONENT;

    COMPONENT LCD_1602A_DISPLAY
        PORT (
            DATA_IN_LINE_1 : IN LCD_MSG_ARRAY;
            DATA_IN_LINE_2 : IN LCD_MSG_ARRAY;
            LCD_RS : OUT STD_LOGIC;
            LCD_E : OUT STD_LOGIC;
            LCD_DATA : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
            CLK_1MHz : IN STD_LOGIC
        );
    END COMPONENT;

    COMPONENT ADC_MCP3208
        PORT (
            RST : IN STD_LOGIC;
            START : IN STD_LOGIC;

            SGL_MODE : IN STD_LOGIC;
            CHANNEL_SELECT : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
            DATA_OUT : OUT STD_LOGIC_VECTOR(11 DOWNTO 0) := (OTHERS => '0');

            IS_BUSY : OUT STD_LOGIC;
            ADC_CLK : OUT STD_LOGIC;
            ADC_CS : OUT STD_LOGIC;
            ADC_MOSI : OUT STD_LOGIC;
            ADC_MISO : IN STD_LOGIC;
            CLK_1MHz : IN STD_LOGIC
        );
    END COMPONENT;

    SIGNAL MESSAGE_LINE_1 : LCD_MSG_ARRAY := (X"88", X"88", X"88", X"88", X"88", X"88", X"88", X"88", X"88", X"88", X"88", X"88", X"88", X"88", X"88", X"88");
    SIGNAL MESSAGE_LINE_2 : LCD_MSG_ARRAY := (X"88", X"88", X"88", X"88", X"88", X"88", X"88", X"88", X"88", X"88", X"88", X"88", X"88", X"88", X"88", X"88");

    SIGNAL clk_1MHz : STD_LOGIC := '0';

    SIGNAL start_adc : STD_LOGIC := '1';
    SIGNAL is_adc_busy : STD_LOGIC := '0';

    SIGNAL adc_channel : STD_LOGIC_VECTOR(2 DOWNTO 0) := b"110";
    SIGNAL adc_data_out : STD_LOGIC_VECTOR(11 DOWNTO 0) := (OTHERS => '0');

    SIGNAL result_3 : unsigned(11 DOWNTO 0);
    SIGNAL result_2 : unsigned(11 DOWNTO 0);
    SIGNAL result_1 : unsigned(11 DOWNTO 0);
    SIGNAL result_0 : unsigned(11 DOWNTO 0);

BEGIN

    CLK_DIV_1MHz : MOD_50 PORT MAP(CLK => clk, RST => '0', CLK_OUT => clk_1MHz);

    LCD_DISPLAY : LCD_1602A_DISPLAY PORT MAP(
        DATA_IN_LINE_1 => MESSAGE_LINE_1,
        DATA_IN_LINE_2 => MESSAGE_LINE_2,
        LCD_RS => lcd_rs,
        LCD_E => lcd_e,
        LCD_DATA => lcd_data,
        CLK_1MHz => clk_1MHz
    );

    result_3 <= (unsigned(adc_data_out) / 1000) + X"30";
    result_2 <= ((unsigned(adc_data_out) / 100) MOD 10) + X"30";
    result_1 <= ((unsigned(adc_data_out) / 10) MOD 10) + X"30";
    result_0 <= (unsigned(adc_data_out) MOD 10) + X"30";

    MESSAGE_LINE_1(0) <= STD_LOGIC_VECTOR(result_3(7 DOWNTO 0));
    MESSAGE_LINE_1(1) <= STD_LOGIC_VECTOR(result_2(7 DOWNTO 0));
    MESSAGE_LINE_1(2) <= STD_LOGIC_VECTOR(result_1(7 DOWNTO 0));
    MESSAGE_LINE_1(3) <= STD_LOGIC_VECTOR(result_0(7 DOWNTO 0));

    PROCESS (CLK_1MHz)
    BEGIN
        IF rising_edge(CLK_1MHz) THEN

            IF start_adc = '1' THEN
                IF is_adc_busy = '1' THEN
                    start_adc <= '0';
                END IF;

            ELSIF is_adc_busy = '0' THEN
                start_adc <= '1';

            END IF;
        END IF;
    END PROCESS;

    ADC : ADC_MCP3208 PORT MAP(
        RST => '0',
        START => start_adc,
        SGL_MODE => '1',
        CHANNEL_SELECT => adc_channel,
        DATA_OUT => adc_data_out,
        IS_BUSY => is_adc_busy,
        ADC_CLK => adc_sck,
        ADC_CS => adc_cs,
        ADC_MOSI => adc_mosi,
        ADC_MISO => adc_miso,
        CLK_1MHz => clk_1MHz
    );

END Behavioral;