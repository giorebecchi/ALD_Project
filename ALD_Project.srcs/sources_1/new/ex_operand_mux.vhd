library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ex_operand_mux is
  generic (XLEN : integer := 32);
  port (
    rs1, rs2, imm, pc : in  std_logic_vector(XLEN-1 downto 0);
    a_sel, b_sel       : in  std_logic_vector(0 downto 0);
    a_out, b_out       : out std_logic_vector(XLEN-1 downto 0)
  );
end entity;

architecture rtl of ex_operand_mux is
  constant ZERO32 : std_logic_vector(XLEN-1 downto 0) := (others => '0');
  constant CONST4 : std_logic_vector(XLEN-1 downto 0) := std_logic_vector(to_unsigned(4, XLEN));
begin
  -- Mux A
  with a_sel select                                
    a_out <= rs1   when "0",                      -- 00 → A = rs1
             pc    when "1",                      -- 01 → A = pc (JAL/JALR) 
             ZERO32 when others;                   -- 10/11 → A = 0 

  -- Mux B
  with b_sel select
    b_out <= rs2   when "0",                      -- 00 → B = rs2 
             imm   when "1",                      -- 01 → B = immediate
             rs2   when others;                    -- non ero molto sicuro quindi ho messo rs2 
end architecture;