library ieee;
use ieee.std_logic_1164.all;

entity forwarding_unit is
  port (
    --output of the instruction currently in EX
    ex_rs1        : in  std_logic_vector(4 downto 0);
    ex_rs2        : in  std_logic_vector(4 downto 0);

    -- instruction currently in MEM 
    mem_rd        : in  std_logic_vector(4 downto 0);
    mem_reg_write : in  std_logic;   -- writes a reg AND is not a load

    -- instruction currently in WB 
    wb_rd         : in  std_logic_vector(4 downto 0);
    wb_reg_write  : in  std_logic;

    --00 = no forward, 01 = from EX/MEM, 10= from MEM/WB
    forward_a     : out std_logic_vector(1 downto 0);
    forward_b     : out std_logic_vector(1 downto 0)
  );
end entity;

architecture rtl of forwarding_unit is
begin
  forward_a <=
    "01" when (mem_reg_write = '1' and mem_rd /= "00000" and mem_rd = ex_rs1) else
    "10" when (wb_reg_write  = '1' and wb_rd  /= "00000" and wb_rd  = ex_rs1) else
    "00";

  forward_b <=
    "01" when (mem_reg_write = '1' and mem_rd /= "00000" and mem_rd = ex_rs2) else
    "10" when (wb_reg_write  = '1' and wb_rd  /= "00000" and wb_rd  = ex_rs2) else
    "00";
end architecture;