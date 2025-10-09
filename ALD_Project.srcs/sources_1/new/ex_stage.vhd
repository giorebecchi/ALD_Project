library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ex_stage is
  generic (XLEN: integer := 32);
  port (
    pc_in, rs1_in, rs2_in, imm_in : in  std_logic_vector(XLEN-1 downto 0);
    funct3_in : in  std_logic_vector(2 downto 0);
    a_sel, b_sel : in  std_logic_vector(1 downto 0);
    alu_mode : in  std_logic_vector(2 downto 0);
    is_branch : in  std_logic;
    alu_result : out std_logic_vector(XLEN-1 downto 0);
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
      mode => alu_mode,
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


  branch_target <= std_logic_vector(signed(pc_in) + signed(imm_in));

  -- Branch taken?
  branch_taken <= '1' when (is_branch = '1' and cond = '1') else '0';

  alu_result <= alu_y;
end architecture;