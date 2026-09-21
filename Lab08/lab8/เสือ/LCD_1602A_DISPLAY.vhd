LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

USE work.LCD_MSG_TYPE.ALL;

ENTITY LCD_1602A_DISPLAY IS
    PORT (
        DATA_IN_LINE_1 : IN LCD_MSG_ARRAY;
        DATA_IN_LINE_2 : IN LCD_MSG_ARRAY;
        LCD_RS : OUT STD_LOGIC;
        LCD_E : OUT STD_LOGIC;
        LCD_DATA : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
        CLK_1MHz : IN STD_LOGIC
    );
END LCD_1602A_DISPLAY;

ARCHITECTURE Behavioral OF LCD_1602A_DISPLAY IS

    COMPONENT LCD_1602A_CORE
        PORT (
            RST : IN STD_LOGIC;
            START : IN STD_LOGIC;

            E_PULSE_DURATION_HIGH : IN INTEGER RANGE 0 TO 25000;
            E_PULSE_DURATION_LOW : IN INTEGER RANGE 0 TO 25000;
            DATA_MODE : IN STD_LOGIC; -- '0' = command, '1' = data
            DATA_IN : IN STD_LOGIC_VECTOR(7 DOWNTO 0);

            IS_BUSY : OUT STD_LOGIC;
            LCD_RS : OUT STD_LOGIC;
            LCD_E : OUT STD_LOGIC;
            LCD_DATA : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
            CLK_1MHz : IN STD_LOGIC
        );
    END COMPONENT;

    TYPE STATE_TYPE IS (
        START_UP,
        INIT1, INIT2, INIT3,
        SETUP_0x38, SETUP_0x08, SETUP_0x01, SETUP_0x06, SETUP_0x0C,
        GOTO_LINE_1, WRITE_LINE_1,
        GOTO_LINE_2, WRITE_LINE_2
    );
    SIGNAL STATE : STATE_TYPE := START_UP;

    SIGNAL tmp_e_pulse_duration_high : INTEGER RANGE 0 TO 25000 := 0;
    SIGNAL tmp_e_pulse_duration_low : INTEGER RANGE 0 TO 25000 := 0;
    SIGNAL tmp_data_mode : STD_LOGIC := '0';
    SIGNAL tmp_data_in : STD_LOGIC_VECTOR(7 DOWNTO 0) := (OTHERS => '0');

    SIGNAL MESSAGE_INDEX : INTEGER RANGE 0 TO 15 := 0;

    --? timing constants
    CONSTANT T_E_HIGH : INTEGER := 5;
    CONSTANT T_SHORT : INTEGER := 50; -- >          37      us : normal command / data
    CONSTANT T_CLEAR : INTEGER := 2000; -- >        1.52    ms : clear / return home
    CONSTANT T_INIT1 : INTEGER := 5000; -- >        4.1     ms : after first 0x30
    CONSTANT T_INIT2 : INTEGER := 200; -- >         100     us : after second 0x30
    CONSTANT T_POWER_ON : INTEGER := 20000; -- >    15      ms : power-on wait

    SIGNAL start_lcd : STD_LOGIC := '0';
    SIGNAL is_lcd_busy : STD_LOGIC;

BEGIN

    -- FSM
    FSM : PROCESS (CLK_1MHz)
    BEGIN
        IF rising_edge(CLK_1MHz) THEN

            IF start_lcd = '1' THEN
                IF is_lcd_busy = '1' THEN
                    start_lcd <= '0';
                END IF;

            ELSIF is_lcd_busy = '0' THEN
                start_lcd <= '1';

                CASE STATE IS
                    WHEN START_UP =>
                        tmp_e_pulse_duration_high <= 0;
                        tmp_e_pulse_duration_low <= T_POWER_ON;
                        tmp_data_mode <= '0';
                        tmp_data_in <= x"00";
                        STATE <= INIT1;

                    WHEN INIT1 =>
                        tmp_e_pulse_duration_high <= T_E_HIGH;
                        tmp_e_pulse_duration_low <= T_INIT1;
                        tmp_data_mode <= '0';
                        tmp_data_in <= x"30";
                        STATE <= INIT2;

                    WHEN INIT2 =>
                        tmp_e_pulse_duration_high <= T_E_HIGH;
                        tmp_e_pulse_duration_low <= T_INIT2;
                        tmp_data_mode <= '0';
                        tmp_data_in <= x"30";
                        STATE <= INIT3;

                    WHEN INIT3 =>
                        tmp_e_pulse_duration_high <= T_E_HIGH;
                        tmp_e_pulse_duration_low <= T_INIT2;
                        tmp_data_mode <= '0';
                        tmp_data_in <= x"30";
                        STATE <= SETUP_0x38;

                    WHEN SETUP_0x38 =>
                        tmp_e_pulse_duration_high <= T_E_HIGH;
                        tmp_e_pulse_duration_low <= T_SHORT;
                        tmp_data_mode <= '0';
                        tmp_data_in <= x"38";
                        STATE <= SETUP_0x08;

                    WHEN SETUP_0x08 =>
                        tmp_e_pulse_duration_high <= T_E_HIGH;
                        tmp_e_pulse_duration_low <= T_SHORT;
                        tmp_data_mode <= '0';
                        tmp_data_in <= x"08";
                        STATE <= SETUP_0x01;

                    WHEN SETUP_0x01 =>
                        tmp_e_pulse_duration_high <= T_E_HIGH;
                        tmp_e_pulse_duration_low <= T_CLEAR;
                        tmp_data_mode <= '0';
                        tmp_data_in <= x"01";
                        STATE <= SETUP_0x06;

                    WHEN SETUP_0x06 =>
                        tmp_e_pulse_duration_high <= T_E_HIGH;
                        tmp_e_pulse_duration_low <= T_SHORT;
                        tmp_data_mode <= '0';
                        tmp_data_in <= x"06";
                        STATE <= SETUP_0x0C;

                    WHEN SETUP_0x0C =>
                        tmp_e_pulse_duration_high <= T_E_HIGH;
                        tmp_e_pulse_duration_low <= T_SHORT;
                        tmp_data_mode <= '0';
                        tmp_data_in <= x"0C";
                        STATE <= GOTO_LINE_1;

                    WHEN GOTO_LINE_1 =>
                        tmp_e_pulse_duration_high <= T_E_HIGH;
                        tmp_e_pulse_duration_low <= T_SHORT;
                        tmp_data_mode <= '0';
                        tmp_data_in <= x"80";
                        MESSAGE_INDEX <= 0;
                        STATE <= WRITE_LINE_1;

                    WHEN WRITE_LINE_1 =>
                        tmp_e_pulse_duration_high <= T_E_HIGH;
                        tmp_e_pulse_duration_low <= T_SHORT;
                        tmp_data_mode <= '1';
                        tmp_data_in <= DATA_IN_LINE_1(MESSAGE_INDEX);
                        IF MESSAGE_INDEX = 15 THEN
                            MESSAGE_INDEX <= 0;
                            STATE <= GOTO_LINE_2;
                        ELSE
                            MESSAGE_INDEX <= MESSAGE_INDEX + 1;
                        END IF;

                    WHEN GOTO_LINE_2 =>
                        tmp_e_pulse_duration_high <= T_E_HIGH;
                        tmp_e_pulse_duration_low <= T_SHORT;
                        tmp_data_mode <= '0';
                        tmp_data_in <= x"C0";
                        MESSAGE_INDEX <= 0;
                        STATE <= WRITE_LINE_2;

                    WHEN WRITE_LINE_2 =>
                        tmp_e_pulse_duration_high <= T_E_HIGH;
                        tmp_e_pulse_duration_low <= T_SHORT;
                        tmp_data_mode <= '1';
                        tmp_data_in <= DATA_IN_LINE_2(MESSAGE_INDEX);
                        IF MESSAGE_INDEX = 15 THEN
                            MESSAGE_INDEX <= 0;
                            STATE <= GOTO_LINE_1;
                        ELSE
                            MESSAGE_INDEX <= MESSAGE_INDEX + 1;
                        END IF;
                END CASE;
            END IF;
        END IF;
    END PROCESS;

    LCD_CORE : LCD_1602A_CORE
    PORT MAP(
        CLK_1MHz => CLK_1MHz,
        RST => '0',
        START => start_lcd,
        E_PULSE_DURATION_HIGH => tmp_e_pulse_duration_high,
        E_PULSE_DURATION_LOW => tmp_e_pulse_duration_low,
        DATA_MODE => tmp_data_mode,
        DATA_IN => tmp_data_in,
        IS_BUSY => is_lcd_busy,
        LCD_RS => LCD_RS,
        LCD_E => LCD_E,
        LCD_DATA => LCD_DATA
    );

END Behavioral;