LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;

ENTITY MOD_10 IS
    PORT (
        CLK, RST : IN STD_LOGIC;
        CLK_OUT : OUT STD_LOGIC;
        Q : OUT STD_LOGIC_VECTOR(3 DOWNTO 0)
    );
END MOD_10;

ARCHITECTURE Behavioral OF MOD_10 IS

    COMPONENT JK_FF IS
        PORT (
            J, K, CLK, RST : IN STD_LOGIC;
            Q, Qn : OUT STD_LOGIC
        );
    END COMPONENT;

    SIGNAL Q0, Q1, Q2, Q3 : STD_LOGIC;
    SIGNAL J0, J1, J2, J3 : STD_LOGIC;
    SIGNAL K0, K1, K2, K3 : STD_LOGIC;

BEGIN
    J0 <= '1';
    K0 <= '1';

    J1 <= Q0 AND (NOT Q3);
    K1 <= Q0;

    J2 <= Q0 AND Q1;
    K2 <= Q0 AND Q1;

    J3 <= Q0 AND Q1 AND Q2;
    K3 <= Q0;

    FF0 : JK_FF PORT MAP(J => J0, K => K0, CLK => CLK, RST => RST, Q => Q0, Qn => OPEN);
    FF1 : JK_FF PORT MAP(J => J1, K => K1, CLK => CLK, RST => RST, Q => Q1, Qn => OPEN);
    FF2 : JK_FF PORT MAP(J => J2, K => K2, CLK => CLK, RST => RST, Q => Q2, Qn => OPEN);
    FF3 : JK_FF PORT MAP(J => J3, K => K3, CLK => CLK, RST => RST, Q => Q3, Qn => OPEN);

    Q <= Q3 & Q2 & Q1 & Q0;

    CLK_OUT <= Q3;

END Behavioral;