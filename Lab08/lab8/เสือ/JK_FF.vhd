LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;

ENTITY JK_FF IS
    PORT (
        J, K, CLK, RST : IN STD_LOGIC;
        Q, Qn : OUT STD_LOGIC
    );
END JK_FF;

ARCHITECTURE Behavioral OF JK_FF IS
    SIGNAL Q_int : STD_LOGIC := '0';
BEGIN
    PROCESS (CLK, RST)
    BEGIN

        IF RST = '1' THEN
            Q_int <= '0';
        ELSIF rising_edge(CLK) THEN
            IF J = '0' AND K = '0' THEN --- Hold
                Q_int <= Q_int;
            ELSIF J = '0' AND K = '1' THEN --- Reset
                Q_int <= '0';
            ELSIF J = '1' AND K = '0' THEN --- Set
                Q_int <= '1';
            ELSIF J = '1' AND K = '1' THEN --- Toggle
                Q_int <= NOT Q_int;
            END IF;
        END IF;

    END PROCESS;

    Q <= Q_int;
    Qn <= NOT Q_int;

END Behavioral;