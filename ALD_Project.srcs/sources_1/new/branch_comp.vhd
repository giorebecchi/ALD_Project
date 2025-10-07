library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity branch_comp is
  generic (XLEN: integer := 32);
  port (
    rs1, rs2    : in  std_logic_vector(XLEN-1 downto 0);
    funct3      : in  std_logic_vector(2 downto 0);
    cond   : out std_logic
  );
end entity;

architecture rtl of branch_comp is
  signal a_s, b_s : signed(XLEN-1 downto 0);
  signal a_u, b_u : unsigned(XLEN-1 downto 0);
begin
  a_s <= signed(rs1); b_s <= signed(rs2);
  a_u <= unsigned(rs1); b_u <= unsigned(rs2);

  process(a_s, b_s, a_u, b_u, funct3)
    variable c : std_logic;
  begin
    case funct3 is
      when "000" => c := '1' when a_u = b_u else '0';  -- BEQ
      when "001" => c := '1' when a_u /= b_u else '0'; -- BNE
      when "100" => c := '1' when a_s < b_s else '0';  -- BLT
      when "101" => c := '1' when a_s >= b_s else '0'; -- BGE
      when "110" => c := '1' when a_u < b_u else '0';  -- BLTU
      when "111" => c := '1' when a_u >= b_u else '0'; -- BGEU
      when others => c := '0';                         -- non-branch 
    end case;
    cond <= c;
  end process;
end architecture;