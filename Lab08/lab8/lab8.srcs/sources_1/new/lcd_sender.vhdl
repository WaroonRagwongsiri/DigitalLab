library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity lcd_sender is
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
end lcd_sender;

architecture Behavioral of lcd_sender is

  component mod32_sync
    Port (
      trigger   : in  STD_LOGIC;
      clk       : in  STD_LOGIC;
      mod32_out : out STD_LOGIC
    );
  end component;

  -- busy: set on trigger, cleared one cycle after the 32-clock e pulse ends
  -- pulsed: set when the 32-clock pulse completes; while busy AND pulsed,
  --         e_pre is low and done is high for exactly one cycle
  signal busy, pulsed : STD_LOGIC := '0';
  signal pulse_done   : STD_LOGIC;
  signal e_pre        : STD_LOGIC;        -- undelayed active state
  signal e_reg        : STD_LOGIC := '0'; -- D-FF: e trails e_pre by one clock

begin

  e_pre <= (not pulsed) and busy;
  done  <= pulsed and busy;

  data_out <= data_in and (7 downto 0 => e_pre);
  rs_out   <= rs_in and e_pre;

  e <= e_reg;

  process(clk)
  begin
    if rising_edge(clk) then
      e_reg <= e_pre;

      if busy = '0' then
        if trigger = '1' then
          busy <= '1';
        end if;
        pulsed <= '0';
      else
        if pulsed = '1' then
          busy <= '0';
        elsif pulse_done = '1' then
          pulsed <= '1';
        end if;
      end if;
    end if;
  end process;

  pulse_width : mod32_sync port map (
    trigger   => e_pre,
    clk       => clk,
    mod32_out => pulse_done
  );

end Behavioral;
