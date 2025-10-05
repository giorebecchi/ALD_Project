-- top_if_fpga.vhd
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity top_if_fpga is
  port (
    CLK100MHZ : in  std_logic;
    BTNC      : in  std_logic; 
    LED       : out std_logic_vector(15 downto 0)
  );
end entity;

architecture rtl of top_if_fpga is
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
  signal if_id_valid  : std_logic;
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
  signal out_bus_write        : std_logic;
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

  -- Regfile signals
  signal a_data, b_data : std_logic_vector(31 downto 0);

begin

  clk <= CLK100MHZ;

  -- Reset synchronization
  process(clk)
  begin
    if rising_edge(clk) then
      rst_btn_meta <= BTNC;
      rst_sync     <= rst_btn_meta; 
    end if;
  end process;

  -- IF stage
  u_if: entity work.if_stage
    generic map (
      ADDR_WIDTH   => IMEM_ADDRW,
      BOOT_PC      => BOOT_PC,
      READ_LATENCY => READ_LATENCY
    )
    port map (
      clk            => clk,
      rst            => rst_sync,
      stall_if       => stall_if,
      redirect_valid => redirect_valid,
      redirect_pc    => redirect_pc,
      imem_dout      => imem_dout,
      imem_en        => imem_en,
      imem_addr      => imem_addr,
      if_id_instr    => if_id_instr,
      if_id_pc       => if_id_pc,
      if_id_valid    => if_id_valid,
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
      instr             => if_id_instr,
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
      rst          => rst_sync,
      rw_select    => out_bus_write,
      data         => out_immed,
      write_select => out_rdest,
      a_select     => out_reg_a,
      b_select     => out_reg_b,
      a_data       => a_data,
      b_data       => b_data
    );

  -- LEDs for quick observation
  LED(7 downto 0)   <= a_data(7 downto 0);
  LED(15 downto 8)  <= b_data(7 downto 0);

end architecture;

