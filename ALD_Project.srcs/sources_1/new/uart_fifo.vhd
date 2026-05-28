-- uart_fifo.vhd

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity uart_fifo is
  generic (
    DATA_WIDTH : integer := 37; 
    DEPTH      : integer := 512
  );
  port (
    clk     : in  std_logic;
    rst     : in  std_logic; 
    wr_en   : in  std_logic;
    wr_data : in  std_logic_vector(DATA_WIDTH-1 downto 0);
    rd_en   : in  std_logic;
    rd_data : out std_logic_vector(DATA_WIDTH-1 downto 0);
    full    : out std_logic;
    empty   : out std_logic
  );
end entity;

architecture rtl of uart_fifo is
  type mem_t is array (0 to DEPTH-1) of std_logic_vector(DATA_WIDTH-1 downto 0);
  signal mem : mem_t := (others => (others => '0'));

  signal wr_ptr : integer range 0 to DEPTH-1 := 0;
  signal rd_ptr : integer range 0 to DEPTH-1 := 0;
  signal count  : integer range 0 to DEPTH   := 0;

  signal full_i  : std_logic;
  signal empty_i : std_logic;
begin

  full_i  <= '1' when count = DEPTH else '0';
  empty_i <= '1' when count = 0     else '0';
  full    <= full_i;
  empty   <= empty_i;
  rd_data <= mem(rd_ptr);

  process(clk)
    variable do_wr : boolean;
    variable do_rd : boolean;
  begin
    if rising_edge(clk) then
      if rst = '0' then
        wr_ptr <= 0;
        rd_ptr <= 0;
        count  <= 0;
      else
        do_wr := (wr_en = '1') and (full_i  = '0');
        do_rd := (rd_en = '1') and (empty_i = '0');

        if do_wr then
          mem(wr_ptr) <= wr_data;
          if wr_ptr = DEPTH-1 then wr_ptr <= 0; else wr_ptr <= wr_ptr + 1; end if;
        end if;

        if do_rd then
          if rd_ptr = DEPTH-1 then rd_ptr <= 0; else rd_ptr <= rd_ptr + 1; end if;
        end if;

        if do_wr and not do_rd then
          count <= count + 1;
        elsif do_rd and not do_wr then
          count <= count - 1;
        end if;
      end if;
    end if;
  end process;

end architecture;