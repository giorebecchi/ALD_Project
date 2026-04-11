library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity seven_segment_display is
    Port (
        clk      : in  STD_LOGIC;                      -- 100 MHz clock
        number   : in  STD_LOGIC_VECTOR(31 downto 0);  -- 32-bit unsigned input
        segments : out STD_LOGIC_VECTOR(6 downto 0);   -- Segments a–g (active low)
        anodes   : out STD_LOGIC_VECTOR(7 downto 0)    -- AN7–AN0 (active low)
    );
end seven_segment_display;

architecture Behavioral of seven_segment_display is
    signal digit_select    : unsigned(2 downto 0) := (others => '0');
    signal value_int       : integer range 0 to 99999999 := 0;
    type digit_array is array (7 downto 0) of unsigned(3 downto 0);
    signal digits          : digit_array;
    signal current_digit   : unsigned(3 downto 0);
    signal counter : unsigned(15 downto 0) := (others => '0');
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
        variable num : integer;
        variable tmp : integer;
    begin
        num := to_integer(unsigned(number));
        if num > 99999999 then
            num := 99999999;  -- saturation
        end if;
        value_int <= num;

        tmp := num;
        for i in 0 to 7 loop
            digits(i) <= to_unsigned(tmp mod 10, 4);
            tmp := tmp / 10;
        end loop;
    end process;

    process(digit_select)
    begin
        case digit_select is
            when "000" => anodes <= "11111110"; -- Digit 0 (rightmost)
            when "001" => anodes <= "11111101";
            when "010" => anodes <= "11111011";
            when "011" => anodes <= "11110111";
            when "100" => anodes <= "11101111";
            when "101" => anodes <= "11011111";
            when "110" => anodes <= "10111111";
            when others => anodes <= "01111111"; -- Digit 7 (leftmost)
        end case;
    end process;

    process(digit_select, digits)
    begin
        case digit_select is
            when "000" => current_digit <= digits(0);
            when "001" => current_digit <= digits(1);
            when "010" => current_digit <= digits(2);
            when "011" => current_digit <= digits(3);
            when "100" => current_digit <= digits(4);
            when "101" => current_digit <= digits(5);
            when "110" => current_digit <= digits(6);
            when others => current_digit <= digits(7);
        end case;
    end process;

   process(current_digit)
   begin
    case current_digit is
        when "0000" => segments <= "1000000"; -- 0
        when "0001" => segments <= "1111001"; -- 1
        when "0010" => segments <= "0100100"; -- 2
        when "0011" => segments <= "0110000"; -- 3
        when "0100" => segments <= "0011001"; -- 4
        when "0101" => segments <= "0010010"; -- 5
        when "0110" => segments <= "0000010"; -- 6
        when "0111" => segments <= "1111000"; -- 7
        when "1000" => segments <= "0000000"; -- 8
        when "1001" => segments <= "0010000"; -- 9
        when others => segments <= "1111111"; -- blank
    end case;
end process;


end Behavioral;
