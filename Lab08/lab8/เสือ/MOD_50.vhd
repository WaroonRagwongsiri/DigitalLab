LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY MOD_50 IS
    PORT (
        CLK, RST : IN STD_LOGIC; -- active high asynchronous reset
        CLK_OUT : OUT STD_LOGIC -- divided-by-50 clock
    );
END MOD_50;

ARCHITECTURE Behavioral OF MOD_50 IS
    SIGNAL counter : INTEGER RANGE 0 TO 49 := 0;
    SIGNAL clk_div : STD_LOGIC := '0';
BEGIN
    PROCESS (CLK, RST)
    BEGIN
        IF RST = '1' THEN
            counter <= 0;
            clk_div <= '0';
        ELSIF rising_edge(CLK) THEN
            IF counter = 49 THEN
                counter <= 0;
                clk_div <= NOT clk_div; -- toggle every 50 clocks → 50% duty cycle
            ELSE
                counter <= counter + 1;
            END IF;
        END IF;
    END PROCESS;

    CLK_OUT <= clk_div;
END Behavioral;