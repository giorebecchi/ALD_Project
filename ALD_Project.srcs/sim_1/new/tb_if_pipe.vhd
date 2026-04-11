library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_if_stage is
end entity;

architecture behavioral of tb_if_stage is

  -- Simulation parameters
  constant CLK_PERIOD : time := 10 ns;   -- 100 MHz clock

  -- DUT signals
  signal clk            : std_logic := '0';
  signal tick_1hz       : std_logic := '0';
  signal rst            : std_logic := '0';
  signal stall_if       : std_logic := '0';
  signal redirect_valid : std_logic := '0';
  signal redirect_pc    : std_logic_vector(31 downto 0) := (others => '0');
  signal imem_dout      : std_logic_vector(31 downto 0);
  signal imem_en        : std_logic;
  signal imem_addr      : std_logic_vector(13 downto 0);
  signal if_id_instr    : std_logic_vector(31 downto 0);
  signal if_id_pc       : std_logic_vector(31 downto 0);
  signal if_id_valid    : std_logic;
  signal pc_out         : std_logic_vector(31 downto 0);

begin

  ---------------------------------------------------------------------------
  -- DUT: Instruction Fetch Stage
  ---------------------------------------------------------------------------
  uut_if : entity work.if_stage
    generic map (
      ADDR_WIDTH   => 14,
      BOOT_PC      => x"00000000",
      READ_LATENCY => 1
    )
    port map (
      clk            => clk,
      tick_1hz       => tick_1hz,
      rst            => rst,
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

  ---------------------------------------------------------------------------
  -- Instruction Memory (ROM / Block Memory)
  ---------------------------------------------------------------------------
  u_imem : entity work.blk_mem_gen_0
    port map (
      clka  => clk,
      ena   => imem_en,
      addra => imem_addr,
      douta => imem_dout
    );

  ---------------------------------------------------------------------------
  -- Clock Generator (100 MHz)
  ---------------------------------------------------------------------------
  clk_proc : process
  begin
    clk <= '0';
    wait for CLK_PERIOD / 2;
    clk <= '1';
    wait for CLK_PERIOD / 2;
  end process;

  ---------------------------------------------------------------------------
  -- 1 Hz Tick Generator (using existing clock_generator entity)
  ---------------------------------------------------------------------------
  uut_clkgen : entity work.clock_generator
    port map (
      clk      => clk,
      reset    => rst,
      tick_1hz => tick_1hz
    );

  ---------------------------------------------------------------------------
  -- Stimulus Process
  ---------------------------------------------------------------------------
  stim_proc : process
  begin

    wait for 1 sec;

    -- End of simulation
    assert false report "Simulation finished successfully." severity failure;
  end process;

end architecture;
