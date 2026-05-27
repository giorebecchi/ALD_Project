-- =============================================================================
-- Testbench - hazard_detection_unit (Updated for Custom ID/EX Interfaces)
-- =============================================================================
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_TEXTIO.ALL;
use STD.TEXTIO.ALL;

entity tb_hazard_detection_unit is
end entity tb_hazard_detection_unit;

architecture sim of tb_hazard_detection_unit is

    -- ── Clock, Reset, and System Signals ──────────────────────────────────────
    signal clk                        : STD_LOGIC := '0';
    signal rst                        : STD_LOGIC := '0';
    signal tick_1hz                   : STD_LOGIC := '1'; -- Default to high to enable sequential state updates
    constant CLK_PERIOD              : time := 20 ns;

    -- ── Updated DUT Input Signals ────────────────────────────────────────────
    signal id_out_reg_a              : STD_LOGIC_VECTOR(4 downto 0) := (others => '0');
    signal id_out_reg_b              : STD_LOGIC_VECTOR(4 downto 0) := (others => '0');
    signal id_out_pc_mode            : STD_LOGIC_VECTOR(1 downto 0) := "11"; -- Default: Reset/No redirect
    signal id_out_branch_test_enable : STD_LOGIC := '0';
    
    signal ex_out_alu_dest_reg       : STD_LOGIC_VECTOR(4 downto 0) := (others => '0');
    signal ex_out_bus_enable         : STD_LOGIC := '0';
    signal ex_out_bus_write          : STD_LOGIC_VECTOR(0 downto 0) := "0";
    signal ex_branch_taken           : STD_LOGIC := '0';

    -- ── DUT Output Signals ───────────────────────────────────────────────────
    signal stall_if                  : STD_LOGIC;
    signal stall_id                  : STD_LOGIC;

    -- ── Helper Procedure for Automated Verification ──────────────────────────
    procedure check (
        test_name    : in string;
        exp_stall_if : in STD_LOGIC;
        exp_stall_id : in STD_LOGIC
    ) is
        variable l : line;
    begin
        wait for 10 ns; -- Sample in the middle of the clock cycle phase
        write(l, string'("[ "));
        if stall_if = exp_stall_if and stall_id = exp_stall_id then
            write(l, string'("PASS"));
        else
            write(l, string'("FAIL"));
        end if;
        write(l, string'(" ] ") & test_name);
        write(l, string'("  stall_if=") ); write(l, stall_if);
        write(l, string'(" stall_id="));    write(l, stall_id);
        write(l, string'("  (exp: "));      write(l, exp_stall_if);
        write(l, string'(","));             write(l, exp_stall_id);
        write(l, string'(")"));
        writeline(output, l);
    end procedure;

begin

    -- =========================================================================
    -- Clock Generation Process
    -- =========================================================================
    clk_process : process
    begin
        clk <= '0';
        wait for CLK_PERIOD / 2;
        clk <= '1';
        wait for CLK_PERIOD / 2;
    end process;
    
    U_CLOCK_GEN : entity work.clock_generator
        port map (
            clk      => clk,
            reset    => rst,
            tick_1hz => tick_1hz
        );
    
    -- =========================================================================
    -- DUT Instantiation
    -- =========================================================================
    DUT : entity work.hazard_detection_unit
        port map (
            clk                       => clk,
            tick_1hz                  => tick_1hz,
            rst                       => rst,
            id_out_reg_a              => id_out_reg_a,
            id_out_reg_b              => id_out_reg_b,
            id_out_pc_mode            => id_out_pc_mode,
            id_out_branch_test_enable => id_out_branch_test_enable,
            ex_out_alu_dest_reg       => ex_out_alu_dest_reg,
            ex_out_bus_enable         => ex_out_bus_enable,
            ex_out_bus_write          => ex_out_bus_write,
            ex_branch_taken           => ex_branch_taken,
            stall_if                  => stall_if,
            stall_id                  => stall_id
        );

    -- =========================================================================
    -- Stimulus Generation Process
    -- =========================================================================
    stim : process
    begin
        -- ── Initialization & Master Reset Pulse ──────────────────────────────
        id_out_reg_a              <= (others => '0'); 
        id_out_reg_b              <= (others => '0');
        id_out_pc_mode            <= "11"; 
        id_out_branch_test_enable <= '0';
        ex_out_alu_dest_reg       <= (others => '0');
        ex_out_bus_enable         <= '0'; 
        ex_out_bus_write          <= "0"; 
        ex_branch_taken           <= '0';
        
        rst <= '1';
        wait for CLK_PERIOD;
        rst <= '0';
        wait for 5 ns; -- Desynchronize input changes away from the rising clock edge

        -- ── TC1: No hazard ───────────────────────────────────────────────────
        id_out_reg_a        <= "00001"; id_out_reg_b <= "00010";
        ex_out_alu_dest_reg <= "00101"; 
        ex_out_bus_enable   <= '0'; ex_out_bus_write <= "0"; -- No load occurring
        id_out_pc_mode      <= "11"; id_out_branch_test_enable <= '0';
        ex_branch_taken     <= '0';
        check("TC1  No hazard", '0', '0');
        wait for 10 ns; -- Finish remaining clock cycle window

        -- ── TC2: Load-use hazard (rs1 match) ─────────────────────────────────
        id_out_reg_a        <= "00011"; id_out_reg_b <= "00100";
        ex_out_alu_dest_reg <= "00011"; 
        ex_out_bus_enable   <= '1'; ex_out_bus_write <= "0"; -- Active LOAD instruction
        check("TC2  Load-use (rs1 match)", '1', '1');
        wait for 10 ns;

        -- ── TC3: Load-use hazard (rs2 match) ─────────────────────────────────
        id_out_reg_a        <= "00001"; id_out_reg_b <= "00011";
        ex_out_alu_dest_reg <= "00011"; 
        ex_out_bus_enable   <= '1'; ex_out_bus_write <= "0"; -- Active LOAD instruction
        check("TC3  Load-use (rs2 match)", '1', '1');
        wait for 10 ns;

        -- ── TC4: Load with rd = x0 (Ignored/No stall) ────────────────────────
        id_out_reg_a        <= "00000"; id_out_reg_b <= "00000";
        ex_out_alu_dest_reg <= "00000"; -- Target x0
        ex_out_bus_enable   <= '1'; ex_out_bus_write <= "0";
        check("TC4  Load rd=x0, no hazard", '0', '0');
        wait for 10 ns;

        -- Clear EX Load states before testing control paths
        ex_out_bus_enable   <= '0'; 
        ex_out_alu_dest_reg <= "00000";
        id_out_reg_a        <= "00001"; id_out_reg_b <= "00010";
        wait for 10 ns;

        -- ── TC5: Branch detected in ID stage ─────────────────────────────────
        id_out_pc_mode            <= "10"; -- PC_JMP_RELATIVE_CONDITIONAL
        id_out_branch_test_enable <= '1';
        check("TC5  Branch in ID", '1', '1');
        id_out_pc_mode            <= "11"; 
        id_out_branch_test_enable <= '0';
        wait for 10 ns;
        
        -- ── TC6: JAL detected in ID stage ────────────────────────────────────
        id_out_pc_mode <= "00"; -- PC_JMP_RELATIVE
        check("TC6  JAL in ID", '1', '1');
        id_out_pc_mode <= "11";
        wait for 10 ns;

        -- ── TC7: JALR detected in ID stage ───────────────────────────────────
        id_out_pc_mode <= "01"; -- PC_JMP_REG_RELATIVE
        check("TC7  JALR in ID", '1', '1');
        id_out_pc_mode <= "11";
        wait for 10 ns;

        -- ── TC8: Branch actually taken out of EX stage ───────────────────────
        ex_branch_taken <= '1';
        check("TC8  Branch taken in EX", '1', '1');
        ex_branch_taken <= '0';
        wait for 10 ns;

        -- ── TC9: Combined Load-use AND branch in ID stage ───────────────────
        id_out_reg_a        <= "00101"; id_out_reg_b <= "00110";
        ex_out_alu_dest_reg <= "00101"; 
        ex_out_bus_enable   <= '1'; ex_out_bus_write <= "0"; -- Load
        id_out_pc_mode      <= "10"; id_out_branch_test_enable <= '1'; -- Branch
        check("TC9  Load-use + branch in ID", '1', '1');
        
        -- Clear all hazards
        id_out_pc_mode            <= "11"; 
        id_out_branch_test_enable <= '0'; 
        ex_out_bus_enable         <= '0';
        wait for 10 ns;

        -- ── TC10: Pipeline recovers gracefully after hazards clear ────────────
        id_out_reg_a        <= "00001"; id_out_reg_b <= "00010";
        ex_out_alu_dest_reg <= "00111"; 
        ex_out_bus_enable   <= '0';
        check("TC10 No hazard after clear", '0', '0');

        wait;
    end process;

end architecture sim;