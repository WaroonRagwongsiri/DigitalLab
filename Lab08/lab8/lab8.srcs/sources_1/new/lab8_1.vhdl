library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity lab8_1 is
  Port (
    clk  : in  STD_LOGIC;
    e    : out STD_LOGIC;
    data : out STD_LOGIC_VECTOR(7 downto 0);
    rs   : out STD_LOGIC
  );
end lab8_1;

architecture Behavioral of lab8_1 is

  component lcd_wait_sync
    Port (
      clk       : in  STD_LOGIC;
      wait_done : out STD_LOGIC
    );
  end component;

  component lcd_sender
    Port (
      trigger  : in  STD_LOGIC;
      rs_in    : in  STD_LOGIC;
      data_in  : in  STD_LOGIC_VECTOR(7 downto 0);
      clk      : in  STD_LOGIC;
      done     : out STD_LOGIC;
      rs_out   : out STD_LOGIC;
      data_out : out STD_LOGIC_VECTOR(7 downto 0);
      e        : out STD_LOGIC
    );
  end component;

  constant N : natural := 16;
  type byte_array is array (0 to N - 1) of STD_LOGIC_VECTOR(7 downto 0);

  constant LCD_BYTES : byte_array := (
    x"38", x"0C", x"06", x"01", x"80",
    x"48", x"65", x"6C", x"6C", x"6F",
    x"20",
    x"57", x"6F", x"72", x"6C", x"64"
  );
  constant LCD_RS : STD_LOGIC_VECTOR(0 to N - 1) := (
    '0', '0', '0', '0', '0',
    '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1'
  );

  signal trigger_chain : STD_LOGIC_VECTOR(0 to N);
  signal sender_e      : STD_LOGIC_VECTOR(0 to N - 1);
  signal sender_rs     : STD_LOGIC_VECTOR(0 to N - 1);
  signal sender_data   : byte_array;

  signal wait_done : STD_LOGIC;
  signal fired     : STD_LOGIC := '0';

begin

  boot_wait : lcd_wait_sync port map (
    clk       => clk,
    wait_done => wait_done
  );

  process(clk)
  begin
    if rising_edge(clk) then
      if wait_done = '1' then
        fired <= '1';
      end if;
    end if;
  end process;

  trigger_chain(0) <= wait_done and not fired;

  senders : for i in 0 to N - 1 generate
    sender : lcd_sender port map (
      trigger  => trigger_chain(i),
      rs_in    => LCD_RS(i),
      data_in  => LCD_BYTES(i),
      clk      => clk,
      done     => trigger_chain(i + 1),
      rs_out   => sender_rs(i),
      data_out => sender_data(i),
      e        => sender_e(i)
    );
  end generate;

  mux : process(sender_e, sender_rs, sender_data)
    variable e_v    : STD_LOGIC;
    variable rs_v   : STD_LOGIC;
    variable data_v : STD_LOGIC_VECTOR(7 downto 0);
  begin
    e_v    := '0';
    rs_v   := '0';
    data_v := (others => '0');
    for i in 0 to N - 1 loop
      e_v    := e_v or sender_e(i);
      rs_v   := rs_v or sender_rs(i);
      data_v := data_v or sender_data(i);
    end loop;
    e    <= e_v;
    rs   <= rs_v;
    data <= data_v;
  end process;

end Behavioral;
