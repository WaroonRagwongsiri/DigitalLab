-- ============================================================
-- Entity: mcp3208_spi
-- SPI master for the MCP3208 12-bit ADC (mode 0,0: SCK idles low,
-- DIN changes on SCK falling edge, DOUT sampled on SCK rising edge).
-- On each 1-cycle `start` pulse (ignored while a conversion is in
-- progress), runs one single-ended conversion on channel 6 -- the
-- board's LDR channel -- and reports the 12-bit result with a
-- 1-cycle `data_valid` pulse when data_out is updated.
--
-- Command sent MSB-first: Start,SGL/DIFF,D2,D1,D0 = "11110"
-- (single-ended, channel D2D1D0="110" = 6), per Lab08 manual sec. 2.
-- Transaction: 5 command bits + 1 null bit + 12 data bits = 18
-- SCK periods total while CS is held low.
--
-- SCK prescale: PRESCALE clk cycles per SCK half-period. With
-- clk = 50 MHz and PRESCALE = 50, SCK ~= 500 kHz, comfortably under
-- the MCP3208's ~1 MHz max at 3.3V (LVCMOS33; no datasheet in-repo,
-- so this is a conservative engineering margin, not a measured spec).
-- ============================================================
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity mcp3208_spi is
  Port (
    clk        : in  STD_LOGIC;
    start      : in  STD_LOGIC;
    SCK        : out STD_LOGIC := '0';
    CS         : out STD_LOGIC := '1';
    DIN        : out STD_LOGIC := '0';
    DOUT       : in  STD_LOGIC;
    data_out   : out STD_LOGIC_VECTOR(11 downto 0) := (others => '0');
    data_valid : out STD_LOGIC := '0'
  );
end mcp3208_spi;

architecture Behavioral of mcp3208_spi is

  constant PRESCALE : integer := 50;  -- clk cycles per SCK half-period (~500kHz SCK @ 50MHz clk)
  constant CMD       : STD_LOGIC_VECTOR(4 downto 0) := "11110"; -- Start,SGL/DIFF,D2,D1,D0 -> channel 6

  type state_t is (S_IDLE, S_XFER, S_DONE);
  signal state     : state_t := S_IDLE;
  signal div_cnt   : integer range 0 to 2*PRESCALE-1 := 0;
  signal bit_index : integer range 0 to 17 := 0;
  signal rx_shift  : STD_LOGIC_VECTOR(11 downto 0) := (others => '0');

  signal dout_sync1, dout_sync2 : STD_LOGIC := '0';  -- 2-FF synchronizer for the external DOUT input
  signal start_d : STD_LOGIC := '0';  -- previous `start`, for rising-edge detect (start is a slow square wave, not a 1-cycle pulse)

begin

  process(clk)
  begin
    if rising_edge(clk) then
      start_d <= start;
    end if;
  end process;

  -- synchronize the external asynchronous DOUT input
  process(clk)
  begin
    if rising_edge(clk) then
      dout_sync1 <= DOUT;
      dout_sync2 <= dout_sync1;
    end if;
  end process;

  process(clk)
  begin
    if rising_edge(clk) then
      case state is

        when S_IDLE =>
          CS         <= '1';
          data_valid <= '0';
          div_cnt    <= 0;
          bit_index  <= 0;
          if start = '1' and start_d = '0' then
            state <= S_XFER;
            CS    <= '0';
          end if;

        when S_XFER =>
          data_valid <= '0';
          if div_cnt = PRESCALE-1 then
            -- SCK about to rise: sample DOUT for the 12 data-bit periods (index 6..17)
            div_cnt <= div_cnt + 1;
            if bit_index >= 6 then
              rx_shift <= rx_shift(10 downto 0) & dout_sync2;
            end if;
          elsif div_cnt = 2*PRESCALE-1 then
            -- SCK about to fall: end of this bit period
            div_cnt <= 0;
            if bit_index = 17 then
              state <= S_DONE;
              CS    <= '1';
            else
              bit_index <= bit_index + 1;
            end if;
          else
            div_cnt <= div_cnt + 1;
          end if;

        when S_DONE =>
          data_out   <= rx_shift;
          data_valid <= '1';
          state      <= S_IDLE;

      end case;
    end if;
  end process;

  -- SCK low during the first half of a bit period, high during the second (CPOL=0)
  SCK <= '1' when (state = S_XFER and div_cnt >= PRESCALE) else '0';

  -- MSB-first command bits during bit periods 0..4; don't-care afterwards
  DIN <= CMD(4 - bit_index) when (state = S_XFER and bit_index <= 4) else '0';

end Behavioral;
