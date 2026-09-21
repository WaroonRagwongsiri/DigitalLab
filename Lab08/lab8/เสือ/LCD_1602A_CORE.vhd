LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY LCD_1602A_CORE IS
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
END LCD_1602A_CORE;

ARCHITECTURE Behavioral OF LCD_1602A_CORE IS

    TYPE LCD_STATE_TYPE IS (IDLE, SETUP, PULSE_HIGH, PULSE_LOW);
    SIGNAL STATE : LCD_STATE_TYPE := IDLE;

    SIGNAL TIMER : INTEGER RANGE 0 TO 25000 := 0;
    SIGNAL T_HIGH : INTEGER RANGE 0 TO 25000 := 0;
    SIGNAL T_LOW : INTEGER RANGE 0 TO 25000 := 0;

    SIGNAL INT_RS : STD_LOGIC := '0';
    SIGNAL INT_DATA : STD_LOGIC_VECTOR(7 DOWNTO 0) := (OTHERS => '0');
    SIGNAL E_PULSE : STD_LOGIC := '0';
    SIGNAL BUSY : STD_LOGIC := '0';

BEGIN

    LCD_RS <= INT_RS;
    LCD_DATA <= INT_DATA;
    LCD_E <= E_PULSE;
    IS_BUSY <= BUSY;

    -- FSM
    FSM : PROCESS (CLK_1MHz)
    BEGIN
        IF rising_edge(CLK_1MHz) THEN
            IF RST = '1' THEN
                STATE <= IDLE;
                TIMER <= 0;
                E_PULSE <= '0';
                BUSY <= '0';
            ELSE
                CASE STATE IS

                    WHEN IDLE =>
                        E_PULSE <= '0';
                        TIMER <= 0;
                        IF START = '1' THEN
                            INT_RS <= DATA_MODE;
                            INT_DATA <= DATA_IN;
                            T_HIGH <= E_PULSE_DURATION_HIGH;
                            T_LOW <= E_PULSE_DURATION_LOW;
                            BUSY <= '1';
                            STATE <= SETUP;
                        ELSE
                            BUSY <= '0';
                        END IF;

                    WHEN SETUP =>
                        E_PULSE <= '0';
                        TIMER <= 0;
                        IF T_HIGH = 0 THEN
                            STATE <= PULSE_LOW;
                        ELSE
                            E_PULSE <= '1';
                            STATE <= PULSE_HIGH;
                        END IF;

                    WHEN PULSE_HIGH =>
                        IF TIMER >= T_HIGH - 1 THEN
                            E_PULSE <= '0';
                            TIMER <= 0;
                            STATE <= PULSE_LOW;
                        ELSE
                            TIMER <= TIMER + 1;
                        END IF;

                    WHEN PULSE_LOW =>
                        IF T_LOW = 0 OR TIMER >= T_LOW - 1 THEN
                            TIMER <= 0;
                            BUSY <= '0';
                            STATE <= IDLE;
                        ELSE
                            TIMER <= TIMER + 1;
                        END IF;

                END CASE;
            END IF;
        END IF;
    END PROCESS;

END Behavioral;