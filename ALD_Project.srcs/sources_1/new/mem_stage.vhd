library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity mem_stage is
  port (
    clk        : in  std_logic;
    tick_1hz   : in std_logic;
    rst        : in  std_logic;

    alu_result       : in  std_logic_vector(31 downto 0);
    b_register_val   : in  std_logic_vector(31 downto 0);
    rd_addr          : in  std_logic_vector(4 downto 0);
    mem_read         : in  std_logic;
    mem_write        : in  std_logic_vector(0 downto 0);
    alu_src          : in  std_logic_vector(1 downto 0);
    in_sign_ex_mode  : in std_logic_vector(0 downto 0);
    in_pc_plus_4     : in std_logic_vector(31 downto 0);
    in_mem_sign_width: in std_logic_vector(1 downto 0);

    dmem_read_data     : in  std_logic_vector(31 downto 0);
    dmem_addr          : out std_logic_vector(11 downto 0);
    dmem_write_data    : out std_logic_vector(31 downto 0);
    dmem_read_en       : out std_logic;
    dmem_write_en      : out std_logic_vector(0 downto 0);
    
    mem_wb_rd_addr     : out std_logic_vector(4 downto 0);
    mem_wb_sign_ex_mode : out std_logic_vector(0 downto 0);
    mem_wb_pc_plus_4    : out std_logic_vector(31 downto 0);
    mem_wb_sign_ex_width: out std_logic_vector(1 downto 0);
    mem_wb_reg_write   : out std_logic;
    mem_wb_mem_to_reg  : out std_logic;
    mem_wb_alu_result  : out std_logic_vector(31 downto 0);
    mem_wb_alu_result_src: out std_logic_vector(1 downto 0);
    mem_wb_load_data   : out std_logic_vector(31 downto 0)
  );
end entity mem_stage;

architecture rtl of mem_stage is

begin

    -------------------------------------------------------
    -- Stage register (pipelined)
    -------------------------------------------------------
    process(clk, rst)
    begin
        if rst = '0' then
            mem_wb_rd_addr    <= (others => '0');
            mem_wb_reg_write  <= '0';
            mem_wb_mem_to_reg <= '0';
            mem_wb_alu_result <= (others => '0');
            mem_wb_load_data  <= (others => '0');

        elsif rising_edge(clk) then
            if tick_1hz = '1' then
                mem_wb_rd_addr    <= rd_addr;
                mem_wb_alu_result <= alu_result;
                mem_wb_load_data  <= dmem_read_data;
                mem_wb_alu_result_src <= alu_src;
                mem_wb_sign_ex_mode <= in_sign_ex_mode;
                mem_wb_pc_plus_4 <= in_pc_plus_4;
                mem_wb_sign_ex_width <= in_mem_sign_width;
                

                if rd_addr /= "00000" then
                    mem_wb_reg_write <= '1';
                else
                    mem_wb_reg_write <= '0';
                end if;

                if alu_src = "10" then
                    mem_wb_mem_to_reg <= '1';
                else
                    mem_wb_mem_to_reg <= '0';
                end if;
            end if;
        end if;
    end process;

    -------------------------------------------------------
    -- Data memory interface
    -------------------------------------------------------
    dmem_addr       <= alu_result(11 downto 0);
    dmem_write_data <= b_register_val;
    dmem_read_en    <= mem_read;
    dmem_write_en   <= mem_write;

   

end architecture rtl;


