library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tb_n_8bit_1_clk_delay is
end tb_n_8bit_1_clk_delay;

architecture sim of tb_n_8bit_1_clk_delay is
  constant CLK_PERIOD : time := 20 ns;

  signal clk        : STD_LOGIC := '0';
  signal n_8bit_in  : STD_LOGIC_VECTOR(7 downto 0) := (others => '0');
  signal n_8bit_out : STD_LOGIC_VECTOR(7 downto 0);
begin

  dut : entity work.n_8bit_1_clk_delay
    port map (n_8bit_in => n_8bit_in, clk => clk, n_8bit_out => n_8bit_out);

  clk_gen : process
  begin
    clk <= '0';
    wait for CLK_PERIOD/2;
    clk <= '1';
    wait for CLK_PERIOD/2;
  end process;

  stim : process
    variable errors  : integer := 0;
    variable prev_in : STD_LOGIC_VECTOR(7 downto 0) := (others => '0');
    type vec_array is array (natural range <>) of STD_LOGIC_VECTOR(7 downto 0);
    constant PATTERNS : vec_array := (
      "00000000", "11111111", "10101010", "01010101", "11001100", "00000001"
    );
  begin
    wait until falling_edge(clk);
    for i in PATTERNS'range loop
      n_8bit_in <= PATTERNS(i);
      wait until falling_edge(clk);
      wait for 1 ns;
      if n_8bit_out /= prev_in then
        report "FAIL: n_8bit_1_clk_delay output does not equal the previous-cycle input at step " &
               integer'image(i) severity error;
        errors := errors + 1;
      end if;
      prev_in := PATTERNS(i);
    end loop;

    if errors = 0 then
      report "PASS: n_8bit_1_clk_delay delays every bit by exactly one clock" severity note;
    end if;
    wait;
  end process;

end sim;
