library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity mem_stage is
  port (
    clk        : in  std_logic;
    tick_1hz   : in  std_logic;
    rst        : in  std_logic;  

    -- From EX/MEM pipe register
    alu_result        : in  std_logic_vector(31 downto 0);
    b_register_val    : in  std_logic_vector(31 downto 0);
    rd_addr           : in  std_logic_vector(4 downto 0);
    mem_read          : in  std_logic;
    mem_write         : in  std_logic_vector(0 downto 0);
    alu_src           : in  std_logic_vector(1 downto 0); 
    in_sign_ex_mode   : in  std_logic_vector(0 downto 0);
    in_pc_plus_4      : in  std_logic_vector(31 downto 0);
    in_mem_sign_width : in  std_logic_vector(1 downto 0);
    loadstore_offset  : in  std_logic_vector(31 downto 0);

    -- DMEM interface
    dmem_read_data    : in  std_logic_vector(31 downto 0);
    dmem_addr         : out std_logic_vector(11 downto 0);
    dmem_write_data   : out std_logic_vector(31 downto 0);
    dmem_read_en      : out std_logic;
    dmem_write_en     : out std_logic_vector(0 downto 0);

    -- To MEM/WB pipe register
    mem_wb_rd_addr        : out std_logic_vector(4 downto 0);
    mem_wb_sign_ex_mode   : out std_logic_vector(0 downto 0);
    mem_wb_pc_plus_4      : out std_logic_vector(31 downto 0);
    mem_wb_sign_ex_width  : out std_logic_vector(1 downto 0);
    mem_wb_reg_write      : out std_logic;
    mem_wb_mem_to_reg     : out std_logic;
    mem_wb_alu_result     : out std_logic_vector(31 downto 0);
    mem_wb_alu_result_src : out std_logic_vector(1 downto 0);
    mem_wb_load_data      : out std_logic_vector(31 downto 0)
  );
end entity mem_stage;

architecture rtl of mem_stage is
    signal is_store     : std_logic;
    signal is_load_inst : std_logic; 
    signal will_write   : std_logic; 
begin
    is_store <= mem_write(0);
    is_load_inst <= '1' when alu_src = "10" else '0';

  
    will_write <= '1' when (rd_addr /= "00000") and (is_store = '0')
                  else '0';

 
    dmem_addr       <= loadstore_offset(13 downto 2);
    dmem_write_data <= b_register_val;


    dmem_read_en     <= mem_read or is_store;
    dmem_write_en(0) <= is_store;

    process(clk, rst)
    begin
        if rst = '0' then
            mem_wb_rd_addr        <= (others => '0');
            mem_wb_reg_write      <= '0';
            mem_wb_mem_to_reg     <= '0';
            mem_wb_alu_result     <= (others => '0');
            mem_wb_load_data      <= (others => '0');
            mem_wb_alu_result_src <= (others => '0');
            mem_wb_sign_ex_mode   <= (others => '0');
            mem_wb_pc_plus_4      <= (others => '0');
            mem_wb_sign_ex_width  <= (others => '0');
        elsif rising_edge(clk) then
            if tick_1hz = '1' then
                mem_wb_rd_addr        <= rd_addr;
                mem_wb_alu_result     <= alu_result;
                mem_wb_load_data      <= dmem_read_data;
                mem_wb_alu_result_src <= alu_src;
                mem_wb_sign_ex_mode   <= in_sign_ex_mode;
                mem_wb_pc_plus_4      <= in_pc_plus_4;
                mem_wb_sign_ex_width  <= in_mem_sign_width;
                mem_wb_reg_write      <= will_write;
                mem_wb_mem_to_reg     <= is_load_inst;
            end if;
        end if;
    end process;
end architecture rtl;