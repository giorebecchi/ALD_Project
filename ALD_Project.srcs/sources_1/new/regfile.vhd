--regfile.vhd
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity regfile is
port(
    clk         :       in std_logic;
    rst         :       in std_logic; 
    rw_select   :       in std_logic;  
    data        :       in std_logic_vector(31 downto 0);
    write_select:       in std_logic_vector(4 downto 0);
    a_select    :       in std_logic_vector(4 downto 0);
    b_select    :       in std_logic_vector(4 downto 0);
    a_data      :       out std_logic_vector(31 downto 0);
    b_data      :       out std_logic_vector(31 downto 0)
    
);
end entity;

architecture rtl of regfile is
type reg_array_t is array (0 to 31) of std_logic_vector(31 downto 0);
signal regs : reg_array_t := (others => (others => '0')); -- initialize to 0
begin
process(clk)
variable selected_reg : integer;
begin
if rising_edge(clk) then
   if rst = '0' then
      regs <= (others => (others => '0'));
   else
       if rw_select = '1' then
             selected_reg := to_integer(unsigned(write_select));
             
          if selected_reg /= 0 then
                    regs(selected_reg) <= data;
          end if;
        end if;
   end if;
end if;
end process;

a_data <= regs(to_integer(unsigned(a_select)));
b_data <= regs(to_integer(unsigned(b_select)));
     


end architecture;