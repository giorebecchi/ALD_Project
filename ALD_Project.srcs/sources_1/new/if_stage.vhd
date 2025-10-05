-- if_stage.vhd
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity if_stage is
  generic (
    ADDR_WIDTH   : natural := 14;                       
    BOOT_PC      : std_logic_vector(31 downto 0) := x"00000000";
    READ_LATENCY : integer := 1                          
  );
  port (
    clk            : in  std_logic;
    rst            : in  std_logic;                     

    -- Hazard / Control
    stall_if       : in  std_logic;
    redirect_valid : in  std_logic;
    redirect_pc    : in  std_logic_vector(31 downto 0); 

    -- IMEM interface (single-port ROM/RAM)
    imem_dout      : in  std_logic_vector(31 downto 0); 
    imem_en        : out std_logic;                     
    imem_addr      : out std_logic_vector(13 downto 0); 

    -- IF/ID pipeline outputs
    if_id_instr    : out std_logic_vector(31 downto 0);
    if_id_pc       : out std_logic_vector(31 downto 0);
    if_id_valid    : out std_logic;

    -- Optional debug
    pc_out         : out std_logic_vector(31 downto 0)
  );
end entity;

architecture rtl of if_stage is
  signal pc_reg     : std_logic_vector(31 downto 0) := (others => '0');
  signal pc_d1      : std_logic_vector(31 downto 0) := (others => '0'); -- 1-cycle delayed PC
  signal pc_d2      : std_logic_vector(31 downto 0) := (others => '0'); -- 2-cycle delayed PC
  signal instr_q    : std_logic_vector(31 downto 0) := (others => '0');
  signal if_pc_q    : std_logic_vector(31 downto 0) := (others => '0');
  signal if_val_q   : std_logic := '0';

  -- helpers
  function clr_lsb(x : std_logic_vector(31 downto 0)) return std_logic_vector is
    variable y : std_logic_vector(31 downto 0) := x;
  begin
    y(0) := '0';  
    return y;
  end function;

  signal next_pc    : std_logic_vector(31 downto 0);
  signal cap_en     : std_logic;  -- capture/advance enable (disabled during stall)
  signal pc_word    : unsigned(31 downto 0);
begin
  
  next_pc <= pc_reg;

  cap_en <= '1' when (stall_if = '0') else '0';

  -- Normal sequential advance when not stalled and no redirect
  -- (actual register update happens in the clocked process)
  
  imem_en   <= '1' when rst = '1' else '0';
  -- Word address to IMEM: PC[31:2]
    -- Word index = PC[ADDR_WIDTH+1 : 2]
    --imem_addr <= pc_reg(ADDR_WIDTH+1 downto 2);
  process(pc_reg)
  begin
     for i in 15 downto 2 loop
        imem_addr(i-2) <= pc_reg(i);
     end loop;
  end process;


  -- Sequential
 
  process(clk)
  begin
    if rising_edge(clk) then
      if rst = '0' then
        pc_reg   <= BOOT_PC;
        pc_d1    <= BOOT_PC;
        pc_d2    <= BOOT_PC;
        instr_q  <= (others => '0');
        if_pc_q  <= (others => '0');
        if_val_q <= '0';
      else
        -- PC update 
        if redirect_valid = '1' then
          pc_reg <= clr_lsb(redirect_pc);
        elsif stall_if = '1' then
          pc_reg <= pc_reg; -- hold
        else
          pc_reg <= std_logic_vector(unsigned(pc_reg) + 4);
        end if;
        -- Align with IMEM latency
        if cap_en = '1' then
          pc_d2 <= pc_d1;
          pc_d1 <= pc_reg;
        end if;
        -- Capture instruction + aligned PC into IF/ID
        if cap_en = '1' then
          instr_q <= imem_dout;

          if READ_LATENCY = 1 then
            if_pc_q <= pc_d1;         -- instr corresponds to PC driven last cycle
          else
            -- Treat any value other than 1 as 2 (supported latencies: 1 or 2)
            if_pc_q <= pc_d2;         -- instr corresponds to PC driven two cycles ago
          end if;

          -- Flush on redirect: the fetch in-flight was wrong-path
          if redirect_valid = '1' then
            if_val_q <= '0';
          else
            if_val_q <= '1';
          end if;
        else
          -- Hold IF/ID outputs during stall
          if_val_q <= if_val_q;
          instr_q  <= instr_q;
          if_pc_q  <= if_pc_q;
        end if;
      end if;
    end if;
  end process;

  -- Outputs
  if_id_instr <= instr_q;
  if_id_pc    <= if_pc_q;
  if_id_valid <= if_val_q;
  pc_out      <= pc_reg;

  -- Optional safety assertions (simulation only)
  assert (READ_LATENCY = 1) or (READ_LATENCY = 2)
    report "if_stage: READ_LATENCY must be 1 or 2" severity warning;
  assert (pc_reg(1 downto 0) = "00")
    report "if_stage: PC not word-aligned" severity warning;

end architecture;
