library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity alu is
  generic (XLEN : integer := 32);
  port (
    a, b     : in  std_logic_vector(XLEN-1 downto 0);
    op       : in  std_logic_vector(2 downto 0);
    result   : out std_logic_vector(XLEN-1 downto 0);
    zero     : out std_logic
  );
end entity;

architecture rtl of alu is
  constant const_zero             : std_logic_vector(31 downto 0) := (others => '0');
  constant ALU_OR                 : std_logic_vector(2 downto 0) := "000";
  constant ALU_AND                : std_logic_vector(2 downto 0) := "001";
  constant ALU_XOR                : std_logic_vector(2 downto 0) := "010";
  constant ALU_UNUSED             : std_logic_vector(2 downto 0) := "011";
  constant ALU_ADD                : std_logic_vector(2 downto 0) := "100";
  constant ALU_SUB                : std_logic_vector(2 downto 0) := "101";
  constant ALU_LESS_THAN_SIGNED   : std_logic_vector(2 downto 0) := "110";
  constant ALU_LESS_THAN_UNSIGNED : std_logic_vector(2 downto 0) := "111";
  
begin
  process(a, b, op)
    variable tmp : std_logic_vector(XLEN-1 downto 0);
  begin
    case op is
      when ALU_OR   => tmp := a or b;

      when ALU_AND  => tmp := a and b;

      when ALU_XOR  => tmp := a xor b;

      when ALU_ADD  => tmp := std_logic_vector(signed(a) + signed(b));

      when ALU_SUB  => tmp := std_logic_vector(signed(a) - signed(b));

      when ALU_LESS_THAN_SIGNED =>
        if signed(a) < signed(b) then
          tmp := (others => '0'); tmp(0) := '1';
        else
          tmp := (others => '0');
        end if;

      when ALU_LESS_THAN_UNSIGNED =>
        if unsigned(a) < unsigned(b) then
          tmp := (others => '0'); tmp(0) := '1';
        else
          tmp := (others => '0');
        end if;

      when others => tmp := (others => '0');
    end case;

    result <= tmp;
    if tmp = const_zero then
        zero   <= '1';
    else 
        zero <= '0';
    end if;
  end process;
end architecture;