library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity clock_generator is
  port (
    clk    : in  std_logic;  -- 100 MHz clock
    reset  : in  std_logic;
    tick_1hz : out std_logic -- 1-cycle pulse at 1 Hz
  );
end entity;

architecture rtl of clock_generator is
  constant MAX_COUNT : unsigned(26 downto 0) := to_unsigned(100_000_000 - 1, 27);
  signal counter     : unsigned(26 downto 0) := (others => '0');
begin
  process(clk, reset)
  begin
    if reset = '0' then
      counter  <= (others => '0');
      tick_1hz <= '0';
    elsif rising_edge(clk) then
      if counter = MAX_COUNT then
        counter  <= (others => '0');
        tick_1hz <= '1';      -- assert for ONE clock cycle
      else
        counter  <= counter + 1;
        tick_1hz <= '0';
      end if;
    end if;
  end process;
end architecture;
