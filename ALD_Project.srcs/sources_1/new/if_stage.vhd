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
    tick_1hz       : in  std_logic;
    rst            : in  std_logic;                     

    -- Hazard / Control
    stall_if       : in  std_logic;
    redirect_valid : in  std_logic;
    redirect_pc    : in  std_logic_vector(31 downto 0); 

    -- IMEM interface (single-port ROM/RAM)
    imem_en        : out std_logic;                     
    imem_addr      : out std_logic_vector(13 downto 0); 

    -- IF/ID pipeline outputs
    if_id_pc       : out std_logic_vector(31 downto 0);

    -- Optional debug
    pc_out         : out std_logic_vector(31 downto 0)
  );
end entity;

architecture rtl of if_stage is
  signal pc_reg     : std_logic_vector(31 downto 0) := (others => '0');
  signal pc_d1      : std_logic_vector(31 downto 0) := (others => '0'); -- 1-cycle delayed PC
  signal if_pc_q    : std_logic_vector(31 downto 0) := (others => '0');
  signal imem_en_int : std_logic := '1';


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
  imem_addr <= pc_reg(15 downto 2);


  -- Sequential
 
  process(clk)
begin
  if rising_edge(clk) then
    if rst = '0' then
      pc_reg   <= BOOT_PC;
      pc_d1    <= BOOT_PC;
      if_pc_q  <= (others => '0');
      imem_en_int <= '1';
    else

      if tick_1hz = '1' then
        if redirect_valid = '1' then
          pc_reg <= clr_lsb(redirect_pc);
        else
          pc_reg <= std_logic_vector(unsigned(pc_reg) + 4);
        end if;

        end if;
      end if;
  end if;
end process;


  if_id_pc    <= pc_reg;
  pc_out      <= pc_reg;
  imem_en <= imem_en_int;


end architecture;
