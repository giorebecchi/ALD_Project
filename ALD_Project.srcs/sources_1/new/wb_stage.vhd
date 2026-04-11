-- wb_stage.vhd
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity wb_stage is
    port(
        -- control from decoder / MEM-WB pipeline register
        in_result_src     : in  std_logic_vector(1 downto 0);
        in_rdest          : in  std_logic_vector(4 downto 0);
        in_sign_ex_mode   : in  std_logic_vector(0 downto 0);
        in_sign_ex_width  : in  std_logic_vector(1 downto 0);

        -- candidate result sources
        in_alu_result     : in  std_logic_vector(31 downto 0);
        in_shift_result   : in  std_logic_vector(31 downto 0);
        in_mem_result     : in  std_logic_vector(31 downto 0);
        in_pc_plus_4      : in  std_logic_vector(31 downto 0);

        -- outputs to register file
        out_write_enable  : out std_logic;
        out_write_reg     : out std_logic_vector(4 downto 0);
        out_write_data    : out std_logic_vector(31 downto 0)
    );
end entity;

architecture rtl of wb_stage is

    -- Same encodings as id_stage
    constant RESULT_ALU             : std_logic_vector(1 downto 0) := "00";
    constant RESULT_SHIFTER         : std_logic_vector(1 downto 0) := "01";
    constant RESULT_MEMORY          : std_logic_vector(1 downto 0) := "10";
    constant RESULT_PC_PLUS_4       : std_logic_vector(1 downto 0) := "11";

    constant SIGN_EX_WIDTH_B        : std_logic_vector(1 downto 0) := "00";
    constant SIGN_EX_WIDTH_H        : std_logic_vector(1 downto 0) := "01";
    constant SIGN_EX_WIDTH_W        : std_logic_vector(1 downto 0) := "10";
    constant SIGN_EX_WIDTH_X        : std_logic_vector(1 downto 0) := "11";

    constant SIGN_EX_SIGNED         : std_logic_vector(0 downto 0) := "0";
    constant SIGN_EX_UNSIGNED       : std_logic_vector(0 downto 0) := "1";

    signal mem_ext_result           : std_logic_vector(31 downto 0);
    signal selected_result          : std_logic_vector(31 downto 0);

begin

    --------------------------------------------------------------------
    -- Load sign/zero extension
    -- Assumes the addressed byte/halfword is already aligned into the
    -- low bits of in_mem_result by the memory stage / bus interface.
    --------------------------------------------------------------------
    mem_extend: process(in_mem_result, in_sign_ex_mode, in_sign_ex_width)
    begin
        case in_sign_ex_width is
            when SIGN_EX_WIDTH_B =>
                if in_sign_ex_mode = SIGN_EX_SIGNED then
                    mem_ext_result <= std_logic_vector(resize(signed(in_mem_result(7 downto 0)), 32));
                else
                    mem_ext_result <= std_logic_vector(resize(unsigned(in_mem_result(7 downto 0)), 32));
                end if;

            when SIGN_EX_WIDTH_H =>
                if in_sign_ex_mode = SIGN_EX_SIGNED then
                    mem_ext_result <= std_logic_vector(resize(signed(in_mem_result(15 downto 0)), 32));
                else
                    mem_ext_result <= std_logic_vector(resize(unsigned(in_mem_result(15 downto 0)), 32));
                end if;

            when SIGN_EX_WIDTH_W =>
                -- full 32-bit word, no further change needed
                mem_ext_result <= in_mem_result;

            when others =>
                -- safe default
                mem_ext_result <= in_mem_result;
        end case;
    end process;

    --------------------------------------------------------------------
    -- Select writeback source
    --------------------------------------------------------------------
    result_mux: process(in_result_src, in_alu_result, in_shift_result, mem_ext_result, in_pc_plus_4)
    begin
        case in_result_src is
            when RESULT_ALU =>
                selected_result <= in_alu_result;

            when RESULT_SHIFTER =>
                selected_result <= in_shift_result;

            when RESULT_MEMORY =>
                selected_result <= mem_ext_result;

            when RESULT_PC_PLUS_4 =>
                selected_result <= in_pc_plus_4;

            when others =>
                selected_result <= (others => '0');
        end case;
    end process;

    --------------------------------------------------------------------
    -- Register file write control
    -- Writes to x0 are suppressed.
    --------------------------------------------------------------------
    out_write_reg  <= in_rdest;
    out_write_data <= selected_result;
    out_write_enable <= '1' when in_rdest /= "00000" else '0';

end architecture;