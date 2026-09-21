LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;

ENTITY ADC_MCP3208 IS
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
END ADC_MCP3208;

ARCHITECTURE Behavioral OF ADC_MCP3208 IS

    TYPE STATE_TYPE IS (
        IDLE,
        START_UP,
        SEND_BIT,
        WAIT_NULL,
        RECEIVE_BIT,
        FINISH
    );
    SIGNAL STATE : STATE_TYPE := IDLE;

    SIGNAL COUNTER : INTEGER RANGE 0 TO 15 := 0;

    SIGNAL INT_CS : STD_LOGIC := '1';
    SIGNAL INT_MOSI : STD_LOGIC := '0';
    SIGNAL SHIFT_CTRL : STD_LOGIC_VECTOR(4 DOWNTO 0) := (OTHERS => '0');
    SIGNAL INT_DATA : STD_LOGIC_VECTOR(11 DOWNTO 0) := (OTHERS => '0');
    SIGNAL MISO_REG : STD_LOGIC := '0';
    SIGNAL BUSY : STD_LOGIC := '0';

BEGIN

    ADC_CS <= INT_CS;
    ADC_MOSI <= INT_MOSI;
    IS_BUSY <= BUSY;
    ADC_CLK <= CLK_1MHz;

    MISO_GET : PROCESS (CLK_1MHz)
    BEGIN
        IF rising_edge(CLK_1MHz) THEN
            MISO_REG <= ADC_MISO;
        END IF;
    END PROCESS;

    -- FSM
    FSM : PROCESS (CLK_1MHz)
    BEGIN
        IF falling_edge(CLK_1MHz) THEN

            IF RST = '1' THEN
                STATE <= IDLE;
                COUNTER <= 0;
                INT_CS <= '1';
                INT_MOSI <= '0';
                SHIFT_CTRL <= (OTHERS => '0');
                INT_DATA <= (OTHERS => '0');
                DATA_OUT <= (OTHERS => '0');
                BUSY <= '0';

            ELSE
                CASE STATE IS

                        ----------------------------------------------------
                    WHEN IDLE =>
                        BUSY <= '0';
                        INT_CS <= '1';
                        INT_MOSI <= '0';
                        COUNTER <= 0;
                        IF START = '1' THEN
                            BUSY <= '1';
                            STATE <= START_UP;
                        END IF;

                        ----------------------------------------------------
                    WHEN START_UP =>
                        INT_CS <= '0';
                        INT_MOSI <= '0';
                        INT_DATA <= (OTHERS => '0');
                        SHIFT_CTRL <= '1' & SGL_MODE & CHANNEL_SELECT;
                        COUNTER <= 0;
                        STATE <= SEND_BIT;

                        ----------------------------------------------------
                    WHEN SEND_BIT =>
                        INT_MOSI <= SHIFT_CTRL(4);
                        SHIFT_CTRL <= SHIFT_CTRL(3 DOWNTO 0) & '0';
                        IF COUNTER = 4 THEN
                            COUNTER <= 0;
                            STATE <= WAIT_NULL;
                        ELSE
                            COUNTER <= COUNTER + 1;
                        END IF;

                        ----------------------------------------------------
                    WHEN WAIT_NULL =>
                        INT_MOSI <= '0';
                        IF COUNTER = 2 THEN
                            COUNTER <= 0;
                            STATE <= RECEIVE_BIT;
                        ELSE
                            COUNTER <= COUNTER + 1;
                        END IF;

                        ----------------------------------------------------
                    WHEN RECEIVE_BIT =>
                        INT_DATA <= INT_DATA(10 DOWNTO 0) & MISO_REG;
                        IF COUNTER = 11 THEN
                            COUNTER <= 0;
                            STATE <= FINISH;
                        ELSE
                            COUNTER <= COUNTER + 1;
                        END IF;

                        ----------------------------------------------------
                    WHEN FINISH =>
                        INT_CS <= '1';
                        INT_MOSI <= '0';
                        DATA_OUT <= INT_DATA;
                        BUSY <= '0';
                        STATE <= IDLE;

                        ----------------------------------------------------
                    WHEN OTHERS =>
                        STATE <= IDLE;

                END CASE;
            END IF;
        END IF;
    END PROCESS;

END Behavioral;