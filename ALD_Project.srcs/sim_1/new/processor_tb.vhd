library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_top is
-- Testbenches do not have ports
end entity;

architecture sim of tb_top is

    -- Constant declarations
    constant CLK_PERIOD : time := 10 ns; -- 100 MHz clock frequency

    -- Signal declarations to connect to the Unit Under Test (UUT)
    signal clk_100mhz_tb : std_logic := '0';
    signal btnc_tb       : std_logic := '0';
    
    -- Outputs from the UUT
    signal ca_tb, cb_tb, cc_tb, cd_tb, ce_tb, cf_tb, cg_tb : std_logic;
    signal dp_tb         : std_logic;
    signal an_tb         : std_logic_vector(7 downto 0);
    signal led_tb        : std_logic_vector(15 downto 0);

begin

    -- 1. Instantiate the Unit Under Test (UUT)
    uut: entity work.top
        port map (
            CLK100MHZ => clk_100mhz_tb,
            BTNC      => btnc_tb,
            CA        => ca_tb,
            CB        => cb_tb,
            CC        => cc_tb,
            CD        => cd_tb,
            CE        => ce_tb,
            CF        => cf_tb,
            CG        => cg_tb,
            DP        => dp_tb,
            AN        => an_tb,
            LED       => led_tb
        );

    -- 2. 100 MHz Clock Generator Process
    clk_process : process
    begin
        while true loop
            clk_100mhz_tb <= '0';
            wait for CLK_PERIOD / 2;
            clk_100mhz_tb <= '1';
            wait for CLK_PERIOD / 2;
        end loop;
        wait; -- Safeguard
    end process;

    -- 3. Stimulus Process
    stim_process : process
    begin
        -- Initial state
        btnc_tb <= '1';
        wait for CLK_PERIOD * 5;

        -- Press the reset button
        -- We hold it for 25 ms because your internal debouncer requires a 20 ms window!
        report "Asserting Reset (Waiting for debouncer...)" severity note;
        btnc_tb <= '0';
        wait for 25 ms; 

        -- Release the reset button
        btnc_tb <= '1';
        report "Reset released. Processor is running." severity note;
        
        -- Let the processor run for an additional 5 ms to monitor execution
        wait for 10000 ms;

        -- End simulation safely
        report "Simulation completed successfully!" severity note;
        wait; 
    end process;

end architecture;