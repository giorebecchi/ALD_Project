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
    when "000" =>  -- BEQ
        if a_u = b_u then
            c := '1';
        else
            c := '0';
        end if;

    when "001" =>  -- BNE
        if a_u /= b_u then
            c := '1';
        else
            c := '0';
        end if;

    when "100" =>  -- BLT
        if a_s < b_s then
            c := '1';
        else
            c := '0';
        end if;

    when "101" =>  -- BGE
        if a_s >= b_s then
            c := '1';
        else
            c := '0';
        end if;

    when "110" =>  -- BLTU
        if a_u < b_u then
            c := '1';
        else
            c := '0';
        end if;

    when "111" =>  -- BGEU
        if a_u >= b_u then
            c := '1';
        else
            c := '0';
        end if;

    when others =>
        c := '0';
end case;

cond <= c;

  end process;
end architecture;