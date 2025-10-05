-- tb_if_stage.vhd
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_if_stage is
end entity;

architecture sim of tb_if_stage is
  ---------------------------------------------------------------------------
  -- CONFIGURE THESE TO MATCH YOUR IMEM IP
  ---------------------------------------------------------------------------
  constant CLK_PERIOD     : time    := 10 ns;  -- 100 MHz
  constant IMEM_ADDRW_IP  : natural := 14;     -- <- set to your IMEM IP Address Width A
  constant READ_LATENCY   : integer := 1;      -- <- 1 or 2, match your IMEM IP setting
  constant BOOT_PC        : std_logic_vector(31 downto 0) := x"00000000";

  ---------------------------------------------------------------------------
  -- DUT / IF-STAGE PORTS
  ---------------------------------------------------------------------------
  signal clk            : std_logic := '0';
  signal rst            : std_logic := '1';

  signal stall_if       : std_logic := '0';
  signal redirect_valid : std_logic := '0';
  signal redirect_pc    : std_logic_vector(31 downto 0) := (others => '0');

  -- IMEM interface between IF-stage and IP
  signal imem_en        : std_logic;
  signal imem_addr      : std_logic_vector(IMEM_ADDRW_IP-1 downto 0);
  signal imem_dout      : std_logic_vector(31 downto 0);

  -- IF → ID outputs to observe
  signal if_id_instr    : std_logic_vector(31 downto 0);
  signal if_id_pc       : std_logic_vector(31 downto 0);
  signal if_id_valid    : std_logic;

  -- Debug
  signal pc_out         : std_logic_vector(31 downto 0);

begin
  ---------------------------------------------------------------------------
  -- CLOCK
  ---------------------------------------------------------------------------
  clk <= not clk after CLK_PERIOD/2;

  ---------------------------------------------------------------------------
  -- DUT: your IF stage
  -- Make sure your if_stage entity/generics match these names.
  ---------------------------------------------------------------------------
  dut: entity work.if_stage
    generic map (
      ADDR_WIDTH   => IMEM_ADDRW_IP,   -- match the IP address width
      BOOT_PC      => BOOT_PC,
      READ_LATENCY => READ_LATENCY
    )
    port map (
      clk            => clk,
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
  -- IMEM IP: Block Memory Generator (Single-Port ROM)
  -- Vivado compiles this IP into library 'xil_defaultlib', not 'work'.
  -- Port names are fixed: clka, ena, addra, douta
  ---------------------------------------------------------------------------
  u_imem: entity work.blk_mem_gen_0
    port map (
      clka  => clk,
      ena   => imem_en,
      addra => imem_addr,
      douta => imem_dout
    );

  ---------------------------------------------------------------------------
  -- STIMULUS
  -- 1) Hold reset a few cycles
  -- 2) Run normally
  -- 3) Insert a 3-cycle stall window
  -- 4) Take a redirect (e.g., to PC=0x10)
  ---------------------------------------------------------------------------
  stim: process
    variable cycles : integer := 0;
  begin
    -- Reset
    rst <= '1';
    stall_if <= '0';
    redirect_valid <= '0';
    redirect_pc <= (others => '0');
    wait for 5*CLK_PERIOD;
    rst <= '0';

    -- Run for some cycles
    for i in 0 to 30 loop
      wait until rising_edge(clk);
      cycles := cycles + 1;

      -- Stall from cycles 6..8 (inclusive of 6, exclusive of 9)
      if cycles = 6 then
        stall_if <= '1';
      elsif cycles = 9 then
        stall_if <= '0';
      end if;

      -- Redirect once at cycle 14
      if cycles = 14 then
        redirect_pc    <= x"00000010"; -- 16 decimal, aligned to 4
        redirect_valid <= '1';
      elsif cycles = 15 then
        redirect_valid <= '0';
      end if;
    end loop;

    -- Let it run a bit more
    for i in 0 to 20 loop
      wait until rising_edge(clk);
    end loop;

    wait; -- end sim
  end process;

  ---------------------------------------------------------------------------
  -- SIMPLE SANITY CHECKS (console asserts)
  ---------------------------------------------------------------------------
  checks: process(clk)
  begin
    if rising_edge(clk) then
      if rst = '0' then
        -- PC is always word-aligned
        assert pc_out(1 downto 0) = "00"
          report "PC not word-aligned!" severity error;

        -- IF/ID alignment: when valid, PC should be stable for instruction capture
        if if_id_valid = '1' then
          -- nothing heavy here; you can add content checks if your COE is known
          null;
        end if;
      end if;
    end if;
  end process;

end architecture;
