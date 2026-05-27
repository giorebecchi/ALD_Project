library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity hazard_detection_unit is
    port (
        clk                       : in  STD_LOGIC;
        tick_1hz                  : in  STD_LOGIC;
        rst                       : in  STD_LOGIC;
        id_out_reg_a              : in  STD_LOGIC_VECTOR(4 downto 0);  -- rs1 source
        id_out_reg_b              : in  STD_LOGIC_VECTOR(4 downto 0);  -- rs2 source
        ex_out_alu_dest_reg       : in  STD_LOGIC_VECTOR(4 downto 0);  -- destination rd
        ex_out_bus_enable         : in  STD_LOGIC;                     -- memory active
        ex_out_bus_write          : in  STD_LOGIC_VECTOR(0 downto 0);  -- 0=Load, 1=Store
        ex_branch_taken           : in  STD_LOGIC;                     -- branch taken result
        stall_if                  : out STD_LOGIC; 
        stall_id                  : out STD_LOGIC 
    );
end entity hazard_detection_unit;

architecture rtl of hazard_detection_unit is

    -- Decoded EX condition
    signal ex_mem_read    : STD_LOGIC;
    signal load_use_comb  : STD_LOGIC;


begin

    -- A LOAD is in EX when the bus is enabled and the write flag is 0.
    ex_mem_read <= '1' when (ex_out_bus_enable = '1' and ex_out_bus_write = "0")
                   else '0';

    -- Load in EX writing a register that ID is about to read (x0 excluded).
    load_use_comb <= '1' when (ex_mem_read = '1' and
                               ex_out_alu_dest_reg /= "00000" and
                               (ex_out_alu_dest_reg = id_out_reg_a or
                                ex_out_alu_dest_reg = id_out_reg_b))
                     else '0';

    stall_if <= load_use_comb;
    stall_id <= load_use_comb;

end architecture rtl;