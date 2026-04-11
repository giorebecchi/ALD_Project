library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ex_stage is
  generic (XLEN: integer := 32);
  port (
    pc_in, rs1_in, rs2_in, imm_in : in  std_logic_vector(XLEN-1 downto 0);
    pc_mode : in std_logic_vector(1 downto 0);
    pc_jump_offset_in   : in std_logic_vector(XLEN-1 downto 0);
    pc_branch_offset_in : in std_logic_vector(XLEN-1 downto 0);
    in_alu_dest_reg : in std_logic_vector(4 downto 0);
    funct3_in : in  std_logic_vector(2 downto 0);
    a_sel, b_sel : in  std_logic_vector(0 downto 0);
    alu_mode : in  std_logic_vector(2 downto 0);
    is_branch : in  std_logic;
    result_src : in std_logic_vector(1 downto 0);
    out_bus_write : in std_logic_vector(0 downto 0);
    out_bus_enable : in std_logic;
    out_bus_width : in std_logic_vector (1 downto 0);
    alu_result : out std_logic_vector(XLEN-1 downto 0);
    pc  : out std_logic_vector(XLEN-1 downto 0);
    result_src_out : out std_logic_vector(1 downto 0);
    b_register_value_out : out std_logic_vector(31 downto 0);
    out_bus_write_out : out std_logic_vector(0 downto 0);
    out_bus_enable_out : out std_logic;
    out_bus_width_out : out std_logic_vector (1 downto 0);
    out_alu_dest_reg : out std_logic_vector(4 downto 0);
    branch_target : out std_logic_vector(XLEN-1 downto 0);
    branch_taken : out std_logic
  );
end entity;

architecture rtl of ex_stage is
  signal op_a, op_b, alu_y : std_logic_vector(XLEN-1 downto 0);
  signal zero_flag, cond : std_logic;
begin
  -- Operand mux
  u_mux : entity work.ex_operand_mux
    generic map (XLEN => XLEN)
    port map (
      rs1 => rs1_in, rs2 => rs2_in, imm => imm_in, pc => pc_in,
      a_sel => a_sel, b_sel => b_sel,
      a_out => op_a, b_out => op_b
    );

  -- ALU
  u_alu : entity work.alu
    generic map (XLEN => XLEN)
    port map (
      a => op_a, b => op_b,
      op => alu_mode,
      result => alu_y,
      zero => zero_flag
    );

  -- Branch comparator
  u_branch : entity work.branch_comp
    generic map (XLEN => XLEN)
    port map (
      rs1 => rs1_in,
      rs2 => rs2_in,
      funct3 => funct3_in,
      cond => cond
    );

process(pc_mode, is_branch, cond, pc_in, rs1_in, imm_in, pc_jump_offset_in, pc_branch_offset_in)
  variable jalr_target_v : std_logic_vector(XLEN-1 downto 0);
begin
  branch_taken  <= '0';
  branch_target <= (others => '0');

  case pc_mode is
    when "00" =>   -- PC_JMP_RELATIVE = JAL
      branch_taken  <= '1';
      branch_target <= std_logic_vector(signed(pc_in) + signed(pc_jump_offset_in));

    when "01" =>   -- PC_JMP_REG_RELATIVE = JALR
      branch_taken  <= '1';
      jalr_target_v := std_logic_vector(signed(rs1_in) + signed(imm_in));
      jalr_target_v(0) := '0';
      branch_target <= jalr_target_v;

    when "10" =>   -- PC_JMP_RELATIVE_CONDITIONAL = branch
      if is_branch = '1' and cond = '1' then
        branch_taken  <= '1';
        branch_target <= std_logic_vector(signed(pc_in) + signed(pc_branch_offset_in));
      end if;

    when "11" =>   -- PC_RESET_STATE / no redirect
      branch_taken  <= '0';
      branch_target <= (others => '0');

    when others =>
      branch_taken  <= '0';
      branch_target <= (others => '0');
  end case;
end process;
  
  pc <= std_logic_vector(unsigned(pc_in) + 4);

  -- Branch taken?
  result_src_out <= result_src;
  b_register_value_out <= rs2_in;
  out_bus_write_out <= out_bus_write;
  out_bus_enable_out <= out_bus_enable;
  out_bus_width_out <= out_bus_width;
  out_alu_dest_reg <= in_alu_dest_reg;

  alu_result <= alu_y;
end architecture;