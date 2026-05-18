library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity seven_segment_display is
    Port (
        clk      : in  STD_LOGIC;                      
        number   : in  STD_LOGIC_VECTOR(31 downto 0);  
        segments : out STD_LOGIC_VECTOR(6 downto 0);   
        anodes   : out STD_LOGIC_VECTOR(7 downto 0)   
    );
end seven_segment_display;

architecture Behavioral of seven_segment_display is
    constant DIG_MINUS : unsigned(4 downto 0) := "10000";  
    constant DIG_BLANK : unsigned(4 downto 0) := "11111";  

    signal digit_select  : unsigned(2 downto 0) := (others => '0');
    type   digit_array is array (7 downto 0) of unsigned(4 downto 0);
    signal digits        : digit_array := (others => DIG_BLANK);
    signal current_digit : unsigned(4 downto 0);
    signal counter       : unsigned(15 downto 0) := (others => '0');
begin
    process(clk)
    begin
        if rising_edge(clk) then
            counter <= counter + 1;
            if counter = 0 then
                digit_select <= digit_select + 1;
            end if;
        end if;
    end process;

    process(number)
        variable num     : integer;
        variable abs_num : integer;
        variable tmp     : integer;
        variable d       : integer range 0 to 9;
        variable is_neg  : boolean;
        variable msd_pos : integer range 0 to 7; 
    begin
        num    := to_integer(signed(number));
        is_neg := (num < 0);

        if is_neg then
            if num < -9999999 then
                abs_num := 9999999;
            else
                abs_num := -num;
            end if;
        else
            if num > 99999999 then
                abs_num := 99999999;
            else
                abs_num := num;
            end if;
        end if;

        tmp     := abs_num;
        msd_pos := 0;
        for i in 0 to 7 loop
            d := tmp mod 10;
            digits(i) <= to_unsigned(d, 5);
            if d /= 0 then
                msd_pos := i;
            end if;
            tmp := tmp / 10;
        end loop;

        for i in 0 to 7 loop
            if i > msd_pos then
                if is_neg and i = msd_pos + 1 then
                    digits(i) <= DIG_MINUS;
                else
                    digits(i) <= DIG_BLANK;
                end if;
            end if;
        end loop;
    end process;

    process(digit_select)
    begin
        case digit_select is
            when "000"  => anodes <= "11111110"; 
            when "001"  => anodes <= "11111101";
            when "010"  => anodes <= "11111011";
            when "011"  => anodes <= "11110111";
            when "100"  => anodes <= "11101111";
            when "101"  => anodes <= "11011111";
            when "110"  => anodes <= "10111111";
            when others => anodes <= "01111111";
        end case;
    end process;

    process(digit_select, digits)
    begin
        case digit_select is
            when "000"  => current_digit <= digits(0);
            when "001"  => current_digit <= digits(1);
            when "010"  => current_digit <= digits(2);
            when "011"  => current_digit <= digits(3);
            when "100"  => current_digit <= digits(4);
            when "101"  => current_digit <= digits(5);
            when "110"  => current_digit <= digits(6);
            when others => current_digit <= digits(7);
        end case;
    end process;

    process(current_digit)
    begin
        case to_integer(current_digit) is
            when 0      => segments <= "1000000"; -- 0
            when 1      => segments <= "1111001"; -- 1
            when 2      => segments <= "0100100"; -- 2
            when 3      => segments <= "0110000"; -- 3
            when 4      => segments <= "0011001"; -- 4
            when 5      => segments <= "0010010"; -- 5
            when 6      => segments <= "0000010"; -- 6
            when 7      => segments <= "1111000"; -- 7
            when 8      => segments <= "0000000"; -- 8
            when 9      => segments <= "0010000"; -- 9
            when 16     => segments <= "0111111"; -- minus sign 
            when others => segments <= "1111111"; -- blank
        end case;
    end process;

end Behavioral;