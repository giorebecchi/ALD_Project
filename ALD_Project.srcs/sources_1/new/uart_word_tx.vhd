
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity uart_word_tx is
  generic (
    CLK_FREQ_HZ : integer := 100_000_000;
    BAUD_RATE   : integer := 115_200
  );
  port (
    clk  : in  std_logic;
    rst  : in  std_logic;                       
    send : in  std_logic;                       
    reg  : in  std_logic_vector(4 downto 0);    
    word : in  std_logic_vector(31 downto 0);   
    busy : out std_logic;                       
    tx   : out std_logic                        
  );
end entity;

architecture rtl of uart_word_tx is

  constant MSG_LEN : integer := 13;  -- 2 reg hex chars + = + 8 value hex chars + CR + LF

  type byte_array_t is array (0 to MSG_LEN-1) of std_logic_vector(7 downto 0);
  signal msg : byte_array_t := (others => (others => '0'));

  type state_t is (IDLE, LOAD, SEND_BYTE, WAIT_BYTE);
  signal state : state_t := IDLE;

  signal idx        : integer range 0 to MSG_LEN := 0;
  signal latched    : std_logic_vector(31 downto 0) := (others => '0');
  signal latched_rd : std_logic_vector(4 downto 0)  := (others => '0');

  signal uart_start : std_logic := '0';
  signal uart_data  : std_logic_vector(7 downto 0) := (others => '0');
  signal uart_busy  : std_logic;


  function hex_ascii(x : std_logic_vector(3 downto 0)) return std_logic_vector is
    variable v : integer;
  begin
    v := to_integer(unsigned(x));
    if v < 10 then
      return std_logic_vector(to_unsigned(v + 48, 8));       -- '0'..'9'
    else
      return std_logic_vector(to_unsigned(v + 55, 8));  -- 'A'..'F'
    end if;
  end function;

begin

  busy <= '0' when state = IDLE else '1';

  u_tx : entity work.uart_tx
    generic map (
      CLK_FREQ_HZ => CLK_FREQ_HZ,
      BAUD_RATE   => BAUD_RATE
    )
    port map (
      clk      => clk,
      rst      => rst,
      tx_start => uart_start,
      tx_data  => uart_data,
      tx_busy  => uart_busy,
      tx       => tx
    );

  process(clk)
  begin
    if rising_edge(clk) then
      if rst = '0' then
        state      <= IDLE;
        idx        <= 0;
        uart_start <= '0';
      else
        uart_start <= '0';   

        case state is

          when IDLE =>
            if send = '1' then
              latched    <= word;
              latched_rd <= reg;
              state      <= LOAD;
            end if;

          when LOAD =>
            -- register number (5 bits) 2 hex chars: high char uses only bit 4.
            msg(0)  <= hex_ascii("000" & latched_rd(4));
            msg(1)  <= hex_ascii(latched_rd(3 downto 0));
            msg(2)  <= x"3D";   -- =
            msg(3)  <= hex_ascii(latched(31 downto 28));
            msg(4)  <= hex_ascii(latched(27 downto 24));
            msg(5)  <= hex_ascii(latched(23 downto 20));
            msg(6)  <= hex_ascii(latched(19 downto 16));
            msg(7)  <= hex_ascii(latched(15 downto 12));
            msg(8)  <= hex_ascii(latched(11 downto  8));
            msg(9)  <= hex_ascii(latched( 7 downto  4));
            msg(10) <= hex_ascii(latched( 3 downto  0));
            msg(11) <= x"0D";   -- carriage return
            msg(12) <= x"0A";   -- line feed
            idx    <= 0;
            state  <= SEND_BYTE;

          when SEND_BYTE =>
            if uart_busy = '0' then
              uart_data  <= msg(idx);
              uart_start <= '1';
              state      <= WAIT_BYTE;
            end if;

          when WAIT_BYTE =>
            if uart_busy = '1' then
              if idx = MSG_LEN-1 then
                state <= IDLE;
              else
                idx   <= idx + 1;
                state <= SEND_BYTE;
              end if;
            end if;

        end case;
      end if;
    end if;
  end process;

end architecture;