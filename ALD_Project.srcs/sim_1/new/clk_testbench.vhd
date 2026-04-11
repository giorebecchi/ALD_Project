library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_my_circuit is
end entity;

architecture sim of tb_my_circuit is

    -- Clock period
    constant CLK_PERIOD : time := 10 ns;  -- 100 MHz clock

    -- DUT signals
    signal clk      : std_logic := '0';
    signal reset_n  : std_logic := '0';
    signal tick_1hz : std_logic;

begin

    -- Instantiate the DUT (Device Under Test)
    uut: entity work.clock_generator
        port map (
            clk      => clk,
            reset  => reset_n,
            tick_1hz => tick_1hz
        );

    --------------------------------------------------------------------
    -- Clock generation
    --------------------------------------------------------------------
    clk_process : process
    begin
        clk <= '0';
        wait for CLK_PERIOD / 2;
        clk <= '1';
        wait for CLK_PERIOD / 2;
    end process clk_process;

    --------------------------------------------------------------------
    -- Reset sequence
    --------------------------------------------------------------------
    stim_proc : process
    begin
        -- hold reset low for 100 ns
        reset_n <= '0';
        wait for 100 ns;
        reset_n <= '1';
        
        -- run simulation long enough to observe tick_1hz
        wait for 2 sec;

        -- stop simulation
        assert false report "Simulation finished" severity failure;
    end process stim_proc;

end architecture sim;
