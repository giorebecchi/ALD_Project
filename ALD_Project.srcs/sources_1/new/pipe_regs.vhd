--pipe_regs.vhd
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity pipe_regs is
port(
    clk         :       in std_logic;
    tick_1hz    :       in std_logic;
    rst         :       in std_logic;
    
 ----------------------------------------------------------------------------------------------------------------------------------
 --INSTRUCTION FETCH DATA
    pc          :       in std_logic_vector(31 downto 0);
    id_ex_pc    :       in std_logic_vector(31 downto 0);
    instr       :       in std_logic_vector(31 downto 0);
    
    
 ----------------------------------------------------------------------------------------------------------------------------------
 --DECODER DATA
    
    --data signals
    rs1_val     :       in std_logic_vector(31 downto 0);
    rs2_val     :       in std_logic_vector(31 downto 0);
    immed       :       in std_logic_vector(31 downto 0);
    rd          :       in std_logic_vector(4 downto 0);
    rs1         :       in std_logic_vector(4 downto 0);
    rs2         :       in std_logic_vector(4 downto 0);
    
    --control signals
    alu_op      :       in std_logic_vector(2 downto 0); --out_alu_mode
    alu_src     :       in std_logic_vector(0 downto 0); --out_select_b (immediate or operand b)
    select_a    :       in std_logic_vector(0 downto 0); --out_select_a (either pc or operand a)
    result_src  :       in std_logic_vector(1 downto 0); --'00' => ALU_RESULT
                                                         --'01' => SHIFTER_RESULT
                                                         --'10' => MEMORY_RESULT
                                                         --'11' => PC_PLUS_4
                                                         
    shift_mode  :       in std_logic_vector (1 downto 0); --'00' SLL,
                                                          --'01' SAL (not used),
                                                          --'10' SLR,
                                                          --'11' SAR
    
    --branch/jump offsets
    pc_mode         :       in std_logic_vector(1 downto 0); --"00" for PC + immediate (JAL)
    pc_jump_offset  :       in std_logic_vector(31 downto 0);--"01" for PC +register(rs1) + immediate (JALR)
    pc_branch_offset:       in std_logic_vector(31 downto 0);--"10" for PC + branch offset IF cond true else +4
                                                             --"11" RESET_PC
    loadstore_offset:      in std_logic_vector(31 downto 0);
    sign_ex_mode    :      in std_logic_vector(0 downto 0); --'0' => signed, '1' => unsigned
    sign_ex_width   :      in std_logic_vector(1 downto 0); --'00' byte
                                                            --'01' halfword
                                                            --'10' word
                                                            --'11' double word
    
    --data memory access info
    mem_write       :       in std_logic_vector(0 downto 0); --bus_write ('1' when write, '0' when read)
    mem_en          :       in std_logic; --bus_enable ('1' when memory instr, '0' when others)
    bus_width       :       in std_logic_vector(1 downto 0); --'00' byte
                                                             --'01' halfword
                                                             --'10' word
                                                             --'11' double word
    
    --branch info
    branch_test_enable :       in std_logic; --'0' don't test for a condition, '1' test
    branch_test_mode   :       in std_logic_vector(2 downto 0); --'000' BEQ,
                                                               --'001' BNE,
                                                               --'100' BLT,
                                                               --'101' BGE,
                                                               --'110' BLTU,
                                                               --'111' BGEU,
                                                               --'010' TRUE,
                                                               --'011' FALSE
 --EXECUTION STAGE DATA
    alu_result          :       in std_logic_vector(31 downto 0);
    pc_4                :       in std_logic_vector(31 downto 0);
    alu_result_src      :       in std_logic_vector(1 downto 0);
    b_register          :       in std_logic_vector(31 downto 0);
    alu_bus_write       :       in std_logic_vector(0 downto 0);
    alu_bus_enable      :       in std_logic;
    alu_bus_width       :       in std_logic_vector(1 downto 0);
    alu_dest_reg        :       in std_logic_vector(4 downto 0);
    branch_target       :       in std_logic_vector(31 downto 0);
    branch_taken        :       in std_logic;
    
 --MEMORY STAGE DATA
    mem_wb_rd_addr      :       in std_logic_vector(4 downto 0);
    mem_wb_reg_write    :       in std_logic;
    mem_wb_mem_to_reg   :       in std_logic;
    mem_wb_alu_result   :       in std_logic_vector(31 downto 0);
    mem_wb_load_data    :       in std_logic_vector(31 downto 0);
    
 ----------------------------------------------------------------------------------------------------------------------------------
        -- OUTPUTS (registered pipeline signals)
        pc_out          : out std_logic_vector(31 downto 0);
        instr_out       : out std_logic_vector(31 downto 0);

        rs1_val_out     : out std_logic_vector(31 downto 0);
        rs2_val_out     : out std_logic_vector(31 downto 0);
        immed_out       : out std_logic_vector(31 downto 0);
        rd_out          : out std_logic_vector(4 downto 0);
        rs1_out         : out std_logic_vector(4 downto 0);
        rs2_out         : out std_logic_vector(4 downto 0);

        alu_op_out      : out std_logic_vector(2 downto 0);
        alu_src_out     : out std_logic_vector(0 downto 0);
        select_a_out    : out std_logic_vector(0 downto 0);
        result_src_out  : out std_logic_vector(1 downto 0);
        shift_mode_out  : out std_logic_vector(1 downto 0);

        pc_mode_out         : out std_logic_vector(1 downto 0);
        pc_jump_offset_out  : out std_logic_vector(31 downto 0);
        pc_branch_offset_out: out std_logic_vector(31 downto 0);
        loadstore_offset_out: out std_logic_vector(31 downto 0);
        sign_ex_mode_out    : out std_logic_vector(0 downto 0);
        sign_ex_width_out   : out std_logic_vector(1 downto 0);

        mem_write_out       : out std_logic_vector(0 downto 0);
        mem_en_out          : out std_logic;
        bus_width_out       : out std_logic_vector(1 downto 0);

        branch_test_enable_out : out std_logic;
        branch_test_mode_out   : out std_logic_vector(2 downto 0);
        
        
        alu_result_out          :       out std_logic_vector(31 downto 0);
        pc_ex_in                :       out std_logic_vector(31 downto 0);
        pc_4_out                :       out std_logic_vector(31 downto 0);
        alu_result_src_out      :       out std_logic_vector(1 downto 0);
        b_register_out          :       out std_logic_vector(31 downto 0);
        alu_bus_write_out       :       out std_logic_vector(0 downto 0);
        alu_bus_enable_out      :       out std_logic;
        alu_bus_width_out       :       out std_logic_vector(1 downto 0);
        alu_dest_reg_out        :       out std_logic_vector(4 downto 0);
        branch_target_out       :       out std_logic_vector(31 downto 0);
        branch_taken_out        :       out std_logic;
        
        mem_wb_rd_addr_out      :       out std_logic_vector(4 downto 0);
        mem_wb_reg_write_out    :       out std_logic;
        mem_wb_mem_to_reg_out   :       out std_logic;
        mem_wb_alu_result_out   :       out std_logic_vector(31 downto 0);
        
        mem_wb_load_data_out    :       out std_logic_vector(31 downto 0)
       
    );

end entity;

architecture rtl of pipe_regs is 
begin
process(clk, rst)
    begin
        if rst = '0' then
            -- reset all pipeline outputs
            pc_out              <= (others => '0');
            pc_ex_in            <= (others => '0');
            instr_out           <= (others => '1');

            rs1_val_out         <= (others => '0');
            rs2_val_out         <= (others => '0');
            immed_out           <= (others => '0');
            rd_out              <= (others => '0');
            rs1_out             <= (others => '0');
            rs2_out             <= (others => '0');

            alu_op_out          <= (others => '0');
            alu_src_out         <= (others => '0');
            select_a_out        <= (others => '0');
            result_src_out      <= (others => '0');
            shift_mode_out      <= (others => '0');

            pc_mode_out         <= (others => '0');
            pc_jump_offset_out  <= (others => '0');
            pc_branch_offset_out<= (others => '0');
            loadstore_offset_out<= (others => '0');
            sign_ex_mode_out    <= (others => '0');
            sign_ex_width_out   <= (others => '0');

            mem_write_out       <= "0";
            mem_en_out          <= '0';
            bus_width_out       <= (others => '0');

            branch_test_enable_out <= '0';
            branch_test_mode_out   <= (others => '0');
            
            alu_result_out <= (others => '0');
            pc_4_out <= (others => '0');
            alu_result_src_out  <= (others => '0');
            b_register_out <= (others => '0');
            alu_bus_write_out <= "0";
            alu_bus_enable_out <= '0';
            alu_bus_width_out <= (others => '0');
            alu_dest_reg_out  <= (others => '0');
            branch_target_out <= (others => '0');
            branch_taken_out  <= '0';

        elsif rising_edge(clk) then
            if tick_1hz = '1' then
            -- latch all inputs into pipeline registers
            pc_out              <= pc;
            pc_ex_in            <= id_ex_pc;
            instr_out           <= instr;

            rs1_val_out         <= rs1_val;
            rs2_val_out         <= rs2_val;
            immed_out           <= immed;
            rd_out              <= rd;
            rs1_out             <= rs1;
            rs2_out             <= rs2;

            alu_op_out          <= alu_op;
            alu_src_out         <= alu_src;
            select_a_out        <= select_a;
            result_src_out      <= result_src;
            shift_mode_out      <= shift_mode;

            pc_mode_out         <= pc_mode;
            pc_jump_offset_out  <= pc_jump_offset;
            pc_branch_offset_out<= pc_branch_offset;
            loadstore_offset_out<= loadstore_offset;
            sign_ex_mode_out    <= sign_ex_mode;
            sign_ex_width_out   <= sign_ex_width;

            mem_write_out       <= mem_write;
            mem_en_out          <= mem_en;
            bus_width_out       <= bus_width;

            branch_test_enable_out <= branch_test_enable;
            branch_test_mode_out   <= branch_test_mode;
            
            alu_result_out <= alu_result;
            branch_target_out <= branch_target;
            branch_taken_out <= branch_taken;
            pc_4_out <= pc_4;
            alu_result_src_out <= alu_result_src;
            b_register_out <= b_register;
            alu_bus_write_out <= alu_bus_write;
            alu_bus_enable_out <= alu_bus_enable;
            alu_bus_width_out <= alu_bus_width;
            alu_dest_reg_out <= alu_dest_reg;
            
            mem_wb_rd_addr_out <= mem_wb_rd_addr;
            mem_wb_reg_write_out <= mem_wb_reg_write;
            mem_wb_mem_to_reg_out <= mem_wb_mem_to_reg;
            mem_wb_alu_result_out <= mem_wb_alu_result;
            mem_wb_load_data_out <= mem_wb_load_data;
        end if;
      end if;
    end process;
end architecture;
