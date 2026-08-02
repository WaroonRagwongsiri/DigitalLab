----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 07/28/2026 04:02:16 PM
-- Design Name: 
-- Module Name: digit_selector - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity digit_selector is
  Port (
    clk : in  STD_LOGIC;
    d3 : out STD_LOGIC;
    d2 : out STD_LOGIC;
    d1 : out STD_LOGIC;
    d0 : out STD_LOGIC
  );
end digit_selector;

architecture Behavioral of digit_selector is
  signal n1_q, n1_qn, n2_q, n2_qn, n6_o, n7_o, n8_o, n9_o : STD_LOGIC;
begin

  -- combinational logic (Perfectly mapped to your AND gates)
  n6_o <= n2_q and n1_q;
  n7_o <= n2_q and n1_qn;
  n8_o <= n2_qn and n1_q;
  n9_o <= n2_qn and n1_qn;

  -- sequential logic (Flip-Flop 1: Toggles every cycle)
  process(clk)
  begin
    if rising_edge(clk) then
      if    (STD_LOGIC'('1')='0' and STD_LOGIC'('1')='1') then n1_q <= '0'; n1_qn <= '1';
      elsif (STD_LOGIC'('1')='1' and STD_LOGIC'('1')='0') then n1_q <= '1'; n1_qn <= '0';
      elsif (STD_LOGIC'('1')='1' and STD_LOGIC'('1')='1') then n1_q <= not n1_q; n1_qn <= n1_q;
      end if;
    end if;
  end process;
  
  -- sequential logic (Flip-Flop 2: Toggles only when FF1 is High)
  process(clk)
  begin
    if rising_edge(clk) then
      if    (n1_q='0' and n1_q='1') then n2_q <= '0'; n2_qn <= '1';
      elsif (n1_q='1' and n1_q='0') then n2_q <= '1'; n2_qn <= '0';
      elsif (n1_q='1' and n1_q='1') then n2_q <= not n2_q; n2_qn <= n2_q;
      end if;
    end if;
  end process;

  -- output drivers
  d3 <= n6_o;
  d2 <= n7_o;
  d1 <= n8_o;
  d0 <= n9_o;

end Behavioral;