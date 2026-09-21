LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;

ENTITY MOD_5 IS
    PORT (
        CLK, RST : IN STD_LOGIC;
        CLK_OUT : OUT STD_LOGIC;
        Q : OUT STD_LOGIC_VECTOR(2 DOWNTO 0)
    );
END MOD_5;

ARCHITECTURE Behavioral OF MOD_5 IS
    COMPONENT JK_FF IS
        PORT (
            J, K, CLK, RST : IN STD_LOGIC;
            Q, Qn : OUT STD_LOGIC
        );
    END COMPONENT;

    SIGNAL Q0, Q1, Q2 : STD_LOGIC;
    SIGNAL J0, J1, J2 : STD_LOGIC;
    SIGNAL K0, K1, K2 : STD_LOGIC;
BEGIN
    J0 <= NOT Q2;
    K0 <= '1';

    J1 <= Q0;
    K1 <= Q0;

    J2 <= Q0 AND Q1;
    K2 <= '1';

    FF0 : JK_FF PORT MAP(J => J0, K => K0, CLK => CLK, RST => RST, Q => Q0, Qn => OPEN);
    FF1 : JK_FF PORT MAP(J => J1, K => K1, CLK => CLK, RST => RST, Q => Q1, Qn => OPEN);
    FF2 : JK_FF PORT MAP(J => J2, K => K2, CLK => CLK, RST => RST, Q => Q2, Qn => OPEN);

    Q <= Q2 & Q1 & Q0;
    CLK_OUT <= Q2;
END Behavioral;