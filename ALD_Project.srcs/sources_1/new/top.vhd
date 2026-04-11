-- top_if_fpga.vhd
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity top is
  port (
    CLK100MHZ : in  std_logic;
    BTNC : in std_logic;
    CA, CB, CC, CD, CE, CF, CG : out STD_LOGIC;     
    DP        : out STD_LOGIC;                     
    AN        : out STD_LOGIC_VECTOR(7 downto 0);
    LED       : out std_logic_vector(15 downto 0)
  );
end entity;

architecture rtl of top is
  constant IMEM_ADDRW   : natural := 12;  
  constant READ_LATENCY : integer := 1;   
  constant BOOT_PC      : std_logic_vector(31 downto 0) := x"00000000";

  signal clk          : std_logic;
  signal rst_btn_meta : std_logic := '1';
  signal rst_sync     : std_logic := '1'; 

  -- IF stage signals
  signal imem_en      : std_logic;
  signal imem_addr    : std_logic_vector(13 downto 0);
  signal imem_dout    : std_logic_vector(31 downto 0);

  signal stall_if       : std_logic := '0';
  signal redirect_valid : std_logic := '0';
  signal redirect_pc    : std_logic_vector(31 downto 0) := (others => '0');

  signal if_id_instr  : std_logic_vector(31 downto 0);
  signal if_id_pc     : std_logic_vector(31 downto 0);
  signal pc_out       : std_logic_vector(31 downto 0);

  -- ID stage signals
  signal out_immed           : std_logic_vector(31 downto 0);
  signal out_reg_a, out_reg_b: std_logic_vector(4 downto 0);
  signal out_select_a, out_select_b: std_logic_vector(0 downto 0);
  signal out_zero_a, out_zero_b: std_logic_vector(0 downto 0);
  signal out_pc_mode          : std_logic_vector(1 downto 0);
  signal out_pc_jump_offset   : std_logic_vector(31 downto 0);
  signal out_pc_branch_offset : std_logic_vector(31 downto 0);
  signal out_loadstore_offset : std_logic_vector(31 downto 0);
  signal out_bus_write        : std_logic_vector(0 downto 0);
  signal out_bus_enable       : std_logic;
  signal out_bus_width        : std_logic_vector(1 downto 0);
  signal out_alu_mode         : std_logic_vector(2 downto 0);
  signal out_branch_test_enable: std_logic;
  signal out_branch_test_mode : std_logic_vector(2 downto 0);
  signal out_shift_mode       : std_logic_vector(1 downto 0);
  signal out_sign_ex_mode     : std_logic_vector(0 downto 0);
  signal out_sign_ex_width    : std_logic_vector(1 downto 0);
  signal out_result_src       : std_logic_vector(1 downto 0);
  signal out_rdest            : std_logic_vector(4 downto 0);
  
  --Alu outputs
  
  signal out_alu_result       : std_logic_vector(31 downto 0);
  signal out_pc_4             : std_logic_vector(31 downto 0);
  signal out_register_b       : std_logic_vector(31 downto 0);
  signal out_alu_result_src   : std_logic_vector(1 downto 0);
  signal out_alu_bus_write    : std_logic_vector(0 downto 0);
  signal out_alu_bus_enable   : std_logic;
  signal out_alu_bus_width    : std_logic_vector(1 downto 0);
  signal out_alu_dest_reg     : std_logic_vector(4 downto 0);
  signal out_branch_target    : std_logic_vector(31 downto 0);
  signal out_branch_taken     : std_logic;

  -- Regfile signals
  signal a_data, b_data : std_logic_vector(31 downto 0);
  --tests
  signal slow_clk : std_logic := '0';
  signal counter   : integer := 0;
  signal rst : std_logic := '0';
  -- PIPE REGS signals (outputs)
  signal pipe_pc_out, pipe_instr_out : std_logic_vector(31 downto 0);
  signal pipe_pc_ex_in : std_logic_vector(31 downto 0);
  signal pipe_rs1_val, pipe_rs2_val, pipe_immed : std_logic_vector(31 downto 0);
  signal pipe_rd, pipe_rs1, pipe_rs2 : std_logic_vector(4 downto 0);
  signal pipe_alu_op : std_logic_vector(2 downto 0);
  signal pipe_alu_src, pipe_select_a : std_logic_vector(0 downto 0);
  signal pipe_result_src : std_logic_vector(1 downto 0);
  signal pipe_shift_mode : std_logic_vector(1 downto 0);
  signal pipe_pc_mode : std_logic_vector(1 downto 0);
  signal pipe_pc_jump_offset, pipe_pc_branch_offset, pipe_loadstore_offset : std_logic_vector(31 downto 0);
  signal pipe_sign_ex_mode : std_logic_vector(0 downto 0);
  signal pipe_sign_ex_width : std_logic_vector(1 downto 0);
  signal pipe_mem_write : std_logic_vector(0 downto 0);
  signal pipe_mem_en : std_logic;
  signal pipe_bus_width : std_logic_vector(1 downto 0);
  signal pipe_branch_test_enable : std_logic;
  signal pipe_branch_test_mode : std_logic_vector(2 downto 0);
  
  signal pipe_alu_result : std_logic_vector(31 downto 0);
  signal pipe_pc_4 : std_logic_vector(31 downto 0);
  signal pipe_register_b : std_logic_vector(31 downto 0);
  signal pipe_alu_result_src : std_logic_vector(1 downto 0);
  signal pipe_alu_bus_write : std_logic_vector(0 downto 0);
  signal pipe_alu_bus_enable : std_logic;
  signal pipe_alu_bus_width : std_logic_vector(1 downto 0);
  signal pipe_dest_reg : std_logic_vector(4 downto 0);
  signal pipe_alu_dest_reg : std_logic_vector(4 downto 0);
  signal pipe_branch_target : std_logic_vector(31 downto 0);
  signal pipe_branch_taken : std_logic;
  
  signal pipe_mem_wb_rd_addr : std_logic_vector(4 downto 0);
  signal pipe_mem_wb_reg_write : std_logic;
  signal pipe_mem_wb_mem_to_reg : std_logic;
  signal pipe_mem_wb_alu_result : std_logic_vector(31 downto 0);
  signal pipe_mem_wb_load_data : std_logic_vector(31 downto 0);
  
  --DMEM signals
  signal dmem_read_data : std_logic_vector(31 downto 0);
  signal dmem_addr : std_logic_vector(11 downto 0);
  signal dmem_write_data : std_logic_vector(31 downto 0);
  signal dmem_read_en : std_logic;
  signal dmem_write_en : std_logic_vector(0 downto 0);
  
  
  signal mem_wb_rd_addr : std_logic_vector(4 downto 0);
  signal mem_wb_reg_write : std_logic;
  signal mem_wb_mem_to_reg : std_logic;
  signal mem_wb_alu_result : std_logic_vector(31 downto 0);
  signal mem_wb_load_data : std_logic_vector(31 downto 0);
  
    -- WB stage signals
  signal wb_write_enable : std_logic;
  signal wb_write_reg    : std_logic_vector(4 downto 0);
  signal wb_write_data   : std_logic_vector(31 downto 0);

  -- extra MEM/WB control needed by wb_stage
  signal mem_wb_result_src    : std_logic_vector(1 downto 0);
  signal mem_wb_pc_plus_4     : std_logic_vector(31 downto 0);
  signal mem_wb_sign_ex_mode  : std_logic_vector(0 downto 0);
  signal mem_wb_sign_ex_width : std_logic_vector(1 downto 0);
  signal mem_wb_alu_result_src : std_logic_vector(1 downto 0);
  signal mem_wb_shift_result  : std_logic_vector(31 downto 0);
  
  
  --seven segment display
  signal segments : STD_LOGIC_VECTOR(6 downto 0);

begin

  clk <= CLK100MHZ;
  
  clock_generator: entity work.clock_generator
   port map (
    clk => clk,
    reset => rst,
    tick_1hz => slow_clk
    );

  process(clk)
  begin
    if rising_edge(clk) then
            rst_btn_meta <= rst;
            rst_sync     <= rst_btn_meta; 
    end if;
  end process;
  debounce_btn1 : entity work.debouncer
    generic map (
        CLK_FREQ_HZ => 100_000_000,
        DEBOUNCE_MS => 20
    )
    port map (
     clk     => clk,
     btn_in  => BTNC,
     btn_out => rst
  );

  -- IF stage
  u_if: entity work.if_stage
    generic map (
      ADDR_WIDTH   => IMEM_ADDRW,
      BOOT_PC      => BOOT_PC,
      READ_LATENCY => READ_LATENCY
    )
    port map (
      clk            => clk,
      tick_1hz       => slow_clk,
      rst            => rst_sync,
      stall_if       => '0',
      redirect_valid => pipe_branch_taken,
      redirect_pc    => pipe_branch_target,
      imem_en        => imem_en,
      imem_addr      => imem_addr,
      if_id_pc       => if_id_pc,
      pc_out         => pc_out
    );
   

  -- Instruction memory
  u_imem: entity work.blk_mem_gen_0
    port map (
      clka  => clk,
      ena   => imem_en,
      addra => imem_addr,
      douta => imem_dout
    );

  -- ID stage
  u_id: entity work.id_stage
    port map (
      rst               => rst_sync,
      minimize_size     => '0',  -- or a test input
      instr             => imem_dout,
      out_immed         => out_immed,
      out_reg_a         => out_reg_a,
      out_select_a      => out_select_a,
      out_zero_a        => out_zero_a,
      out_reg_b         => out_reg_b,
      out_select_b      => out_select_b,
      out_zero_b        => out_zero_b,
      out_pc_mode       => out_pc_mode,
      out_pc_jump_offset=> out_pc_jump_offset,
      out_pc_branch_offset=> out_pc_branch_offset,
      out_loadstore_offset=> out_loadstore_offset,
      out_bus_write     => out_bus_write,
      out_bus_enable    => out_bus_enable,
      out_bus_width     => out_bus_width,
      out_alu_mode      => out_alu_mode,
      out_branch_test_enable => out_branch_test_enable,
      out_branch_test_mode   => out_branch_test_mode,
      out_shift_mode    => out_shift_mode,
      out_sign_ex_mode  => out_sign_ex_mode,
      out_sign_ex_width => out_sign_ex_width,
      out_result_src    => out_result_src,
      out_rdest         => out_rdest
    );

  -- Register file
    u_regfile: entity work.regfile
    port map (
      clk          => clk,
      tick_1hz     => slow_clk,
      rst          => rst_sync,
      rw_select    => wb_write_enable,
      data         => wb_write_data,
      write_select => wb_write_reg,
      a_select     => out_reg_a,
      b_select     => out_reg_b,
      a_data       => a_data,
      b_data       => b_data
    );
   u_exstage: entity work.ex_stage
    port map (
        pc_in => pipe_pc_ex_in,
        rs1_in => pipe_rs1_val,
        rs2_in => pipe_rs2_val,
        imm_in => pipe_immed,
        pc_mode => pipe_pc_mode,
        pc_jump_offset_in => pipe_pc_jump_offset,
        pc_branch_offset_in => pipe_pc_branch_offset,
        in_alu_dest_reg => pipe_rd,
        funct3_in => pipe_branch_test_mode,
        a_sel => pipe_select_a,
        b_sel => pipe_alu_src,
        alu_mode => pipe_alu_op,
        is_branch => pipe_branch_test_enable,
        result_src => pipe_result_src,
        out_bus_write => pipe_mem_write,
        out_bus_enable => pipe_mem_en,
        out_bus_width => pipe_bus_width,
        alu_result => out_alu_result,
        pc => out_pc_4,
        result_src_out => out_alu_result_src,
        b_register_value_out => out_register_b,
        out_bus_write_out => out_alu_bus_write,
        out_bus_enable_out => out_alu_bus_enable,
        out_bus_width_out => out_alu_bus_width,
        out_alu_dest_reg => out_alu_dest_reg,
        branch_target => out_branch_target,
        branch_taken => out_branch_taken 
     ); 
    u_piperegs: entity work.pipe_regs
     port map (
      clk => clk,
      tick_1hz => slow_clk,
      rst => rst_sync,

      pc => if_id_pc,
      id_ex_pc => pipe_pc_out,
      instr => if_id_instr,

      rs1_val => a_data,
      rs2_val => b_data,
      immed => out_immed,
      rd => out_rdest,
      rs1 => out_reg_a,
      rs2 => out_reg_b,

      alu_op => out_alu_mode,
      alu_src => out_select_b,
      select_a => out_select_a,
      result_src => out_result_src,
      shift_mode => out_shift_mode,

      pc_mode => out_pc_mode,
      pc_jump_offset => out_pc_jump_offset,
      pc_branch_offset => out_pc_branch_offset,
      loadstore_offset => out_loadstore_offset,
      sign_ex_mode => out_sign_ex_mode,
      sign_ex_width => out_sign_ex_width,

      mem_write => out_bus_write,
      mem_en => out_bus_enable,
      bus_width => out_bus_width,

      branch_test_enable => out_branch_test_enable,
      branch_test_mode => out_branch_test_mode,
      
      alu_result => out_alu_result,
      pc_4 => out_pc_4,
      alu_result_src => out_alu_result_src,
      b_register => out_register_b,
      alu_bus_write => out_alu_bus_write,
      alu_bus_enable => out_alu_bus_enable,
      alu_bus_width => out_alu_bus_width,
      alu_dest_reg => out_alu_dest_reg,
      branch_target => out_branch_target,
      branch_taken => out_branch_taken, 
      
      mem_wb_rd_addr => mem_wb_rd_addr,
      mem_wb_reg_write => mem_wb_reg_write,
      mem_wb_mem_to_reg => mem_wb_mem_to_reg, 
      mem_wb_alu_result => mem_wb_alu_result,
      mem_wb_load_data => mem_wb_load_data,
      

      -- Outputs (to EX stage)
      pc_out => pipe_pc_out,
      pc_ex_in => pipe_pc_ex_in,
      instr_out => pipe_instr_out,

      rs1_val_out => pipe_rs1_val,
      rs2_val_out => pipe_rs2_val,
      immed_out => pipe_immed,
      rd_out => pipe_rd,
      rs1_out => pipe_rs1,
      rs2_out => pipe_rs2,

      alu_op_out => pipe_alu_op,
      alu_src_out => pipe_alu_src,
      select_a_out => pipe_select_a,
      result_src_out => pipe_result_src,
      shift_mode_out => pipe_shift_mode,

      pc_mode_out => pipe_pc_mode,
      pc_jump_offset_out => pipe_pc_jump_offset,
      pc_branch_offset_out => pipe_pc_branch_offset,
      loadstore_offset_out => pipe_loadstore_offset,
      sign_ex_mode_out => pipe_sign_ex_mode,
      sign_ex_width_out => pipe_sign_ex_width,

      mem_write_out => pipe_mem_write,
      mem_en_out => pipe_mem_en,
      bus_width_out => pipe_bus_width,

      branch_test_enable_out => pipe_branch_test_enable,
      branch_test_mode_out => pipe_branch_test_mode,
      
      alu_result_out => pipe_alu_result,
      pc_4_out => pipe_pc_4,
      alu_result_src_out => pipe_alu_result_src,
      b_register_out => pipe_register_b,
      alu_bus_write_out => pipe_alu_bus_write,
      alu_bus_enable_out => pipe_alu_bus_enable,
      alu_bus_width_out => pipe_alu_bus_width,
      alu_dest_reg_out => pipe_alu_dest_reg,
      branch_target_out => pipe_branch_target,
      branch_taken_out => pipe_branch_taken,
      
      mem_wb_rd_addr_out => pipe_mem_wb_rd_addr, 
      mem_wb_reg_write_out => pipe_mem_wb_reg_write, 
      mem_wb_mem_to_reg_out => pipe_mem_wb_mem_to_reg, 
      mem_wb_alu_result_out => pipe_mem_wb_alu_result, 
      mem_wb_load_data_out => pipe_mem_wb_load_data 
    );
    u_mem_stage: entity work.mem_stage
        port map(
        clk => clk,
        tick_1hz => slow_clk,
        rst => rst_sync,
        
        alu_result => pipe_alu_result,
        b_register_val => pipe_register_b,
        rd_addr => pipe_alu_dest_reg,
        mem_read => pipe_alu_bus_enable,
        mem_write => pipe_alu_bus_write,
        alu_src => pipe_alu_result_src,
        in_sign_ex_mode => pipe_sign_ex_mode,
        in_pc_plus_4 => pipe_pc_4,
        in_mem_sign_width=>pipe_sign_ex_width,
        
        dmem_read_data => dmem_read_data, 
        dmem_addr => dmem_addr, 
        dmem_write_data => dmem_write_data, 
        dmem_read_en => dmem_read_en, 
        dmem_write_en => dmem_write_en, 
        
        
        mem_wb_sign_ex_mode => mem_wb_sign_ex_mode,
        mem_wb_sign_ex_width => mem_wb_sign_ex_width,
        mem_wb_rd_addr => pipe_dest_reg,
        mem_wb_reg_write => mem_wb_reg_write, 
        mem_wb_mem_to_reg => mem_wb_mem_to_reg, 
        mem_wb_alu_result => mem_wb_alu_result, 
        mem_wb_alu_result_src => mem_wb_alu_result_src,
        mem_wb_pc_plus_4 => mem_wb_pc_plus_4,
        mem_wb_load_data => mem_wb_load_data 
        );
    u_dmem: entity work.dmem
        port map(
            addra => dmem_addr,
            clka => clk,
            dina => dmem_write_data,
            douta => dmem_read_data,
            ena => dmem_read_en,
            wea => dmem_write_en
         );

    -- No separate shifter result path currently exists in top,
    -- so use ALU result unless you expose a real shift result from EX.
    mem_wb_shift_result  <= mem_wb_alu_result;
    u_wb_stage: entity work.wb_stage
        port map (
        in_result_src     => mem_wb_alu_result_src,
        in_rdest          => pipe_dest_reg,
        in_sign_ex_mode   => mem_wb_sign_ex_mode,
        in_sign_ex_width  => mem_wb_sign_ex_width,

        in_alu_result     => mem_wb_alu_result,
        in_shift_result   => mem_wb_shift_result,
        in_mem_result     => mem_wb_load_data,
        in_pc_plus_4      => mem_wb_pc_plus_4,

        out_write_enable  => wb_write_enable,
        out_write_reg     => wb_write_reg,
        out_write_data    => wb_write_data
      );
        
    u_seven_segment_display: entity work.seven_segment_display
        port map(
            clk => clk,
            number => wb_write_data,
            segments => segments,
            anodes => AN
        );
    CA <= segments(0);
    CB <= segments(1);
    CC <= segments(2);
    CD <= segments(3);
    CE <= segments(4);
    CF <= segments(5);
    CG <= segments(6);
    DP <= '1'; -- keep decimal point off (active low)
    LED(15 downto 6) <= imem_dout(9 downto 0);
    LED(5 downto 1) <= pipe_dest_reg;
    LED(0) <= pipe_branch_taken;


end architecture;

