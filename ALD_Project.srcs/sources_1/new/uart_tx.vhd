
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity uart_tx is
  generic (
    CLK_FREQ_HZ : integer := 100_000_000;  -- input clock frequency
    BAUD_RATE   : integer := 115_200       -- target baud rate
  );
  port (
    clk      : in  std_logic;
    rst      : in  std_logic;                     
    tx_start : in  std_logic;                      
    tx_data  : in  std_logic_vector(7 downto 0);   
    tx_busy  : out std_logic;                      
    tx       : out std_logic                      
  );
end entity;

architecture rtl of uart_tx is

  constant DIVISOR : integer := CLK_FREQ_HZ / BAUD_RATE;

  type state_t is (IDLE, START_BIT, DATA_BITS, STOP_BIT);
  signal state : state_t := IDLE;

  signal baud_cnt : integer range 0 to DIVISOR-1 := 0;
  signal bit_idx  : integer range 0 to 7 := 0;
  signal shreg    : std_logic_vector(7 downto 0) := (others => '0');
  signal tx_r     : std_logic := '1';
  signal busy_r   : std_logic := '0';
begin

  tx      <= tx_r;
  tx_busy <= busy_r;

  process(clk)
  begin
    if rising_edge(clk) then
      if rst = '0' then
        state    <= IDLE;
        tx_r     <= '1';
        busy_r   <= '0';
        baud_cnt <= 0;
        bit_idx  <= 0;
      else
        case state is

          when IDLE =>
            tx_r     <= '1';
            busy_r   <= '0';
            baud_cnt <= 0;
            bit_idx  <= 0;
            if tx_start = '1' then
              shreg  <= tx_data;
              busy_r <= '1';
              state  <= START_BIT;
            end if;

          when START_BIT =>
            tx_r <= '0';                          -- start bit
            if baud_cnt = DIVISOR-1 then
              baud_cnt <= 0;
              bit_idx  <= 0;
              state    <= DATA_BITS;
            else
              baud_cnt <= baud_cnt + 1;
            end if;

          when DATA_BITS =>
            tx_r <= shreg(bit_idx);               -- LSB first
            if baud_cnt = DIVISOR-1 then
              baud_cnt <= 0;
              if bit_idx = 7 then
                state <= STOP_BIT;
              else
                bit_idx <= bit_idx + 1;
              end if;
            else
              baud_cnt <= baud_cnt + 1;
            end if;

          when STOP_BIT =>
            tx_r <= '1';                          -- stop bit
            if baud_cnt = DIVISOR-1 then
              baud_cnt <= 0;
              busy_r   <= '0';
              state    <= IDLE;
            else
              baud_cnt <= baud_cnt + 1;
            end if;

        end case;
      end if;
    end if;
  end process;

end architecture;