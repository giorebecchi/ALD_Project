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
    a_out <= rs1   when "0",                      
             pc    when "1",                     
             ZERO32 when others;                   

  -- Mux B
  with b_sel select
    b_out <= rs2   when "0",                 
             imm   when "1",                     
             rs2   when others;                    
end architecture;