library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity debouncer is
    generic (
        CLK_FREQ_HZ  : integer := 100_000_000; 
        DEBOUNCE_MS  : integer := 20          
    );
    port (
        clk      : in  std_logic;  
        btn_in   : in  std_logic;  
        btn_out  : out std_logic  
    );
end entity debouncer;

architecture Behavioral of debouncer is
    constant MAX_COUNT : integer := (CLK_FREQ_HZ / 1000) * DEBOUNCE_MS;

    signal counter   : unsigned(31 downto 0) := (others => '0');
    signal btn_sync  : std_logic_vector(1 downto 0) := (others => '0');
    signal btn_state : std_logic := '0';
begin

    process(clk)
    begin
        if rising_edge(clk) then
            btn_sync(0) <= btn_in;
            btn_sync(1) <= btn_sync(0);
        end if;
    end process;

    process(clk)
    begin
        if rising_edge(clk) then
            if btn_sync(1) /= btn_state then
             
                counter <= counter + 1;
                if counter > MAX_COUNT then
                    btn_state <= btn_sync(1);
                    counter   <= (others => '0');
                end if;
            else
               
                counter <= (others => '0');
            end if;
        end if;
    end process;

    btn_out <= not btn_state;

end architecture Behavioral;
