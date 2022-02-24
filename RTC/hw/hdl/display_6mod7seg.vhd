library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity display_6mod7seg is port(
    clk : in std_logic;
    nReset : in std_logic;
    --Internalin terface(i.e.Avalonslave).
    address : in std_logic_vector(2 downto 0);
    write : in std_logic;
    read : in std_logic;

    writedata : in std_logic_vector(7 downto 0);
    readdata : out std_logic_vector(7 downto 0);

    --External interface(i.e.conduit).
    selSeg : out std_logic_vector(7 downto 0);
    nSelDig: out std_logic_vector(5 downto 0);
    Reset_Led: out std_logic
);
end display_6mod7seg;

architecture comp of display_6mod7seg is
    constant clk_reduction : natural := 8333;
    constant mask_RTC : std_logic_vector(5 downto 0) := "010100";
    type carry_RTC_type is array (0 to 5) of natural range 0 to 9;
    constant carry_RTC : carry_RTC_type := (9, 9, 9, 5, 9, 9);

    type seg7Lookup_type is array (0 to 9) of std_logic_vector(6 downto 0);
    constant seg7Lookup : seg7Lookup_type :=
       ("1111110",
        "0110000",
        "1101101",
        "1111001",
        "0110011",
        "1011011",
        "1011111",
        "1110000",
        "1111111",
        "1111011");

    signal mask_reg : std_logic_vector(5 downto 0);
    signal Reset_Led_internal : std_logic;

    signal clk_en : std_logic;
    signal display_en : std_logic;
    signal selDig_internal: natural range 0 to 5;
    signal nSelDig_internal: std_logic_vector(nSelDig'range);

    type number_array_type is array (5 downto 0) of std_logic_vector(4 downto 0);
    signal num_array_reg : number_array_type;
    signal RTC_array_reg: number_array_type;
    type selSeg_array_type is array (5 downto 0) of std_logic_vector(7 downto 0);
    signal selSeg_array: selSeg_array_type;

    signal reset_act_cnt : natural range 0 to 5;

    signal RTC : std_logic;
begin

-- Clock enable process ("slowing" main clock)
process(nReset, clk)
    -- We want to reach 6kHz (diminution factor of ~8333x)
    variable cnt : natural range 0 to clk_reduction-1 := 0;
begin
    if nReset = '0' then
        cnt := 0;
    elsif rising_edge(clk) then
        cnt := (cnt + 1) mod clk_reduction; --8333;

        if cnt = clk_reduction-1 then
            clk_en <= '1';
        else
            clk_en <= '0';
        end if;
    end if;
end process;

-- Reset/Act logic
process(nReset, clk)
begin
    if nReset = '0' then
        reset_act_cnt <= 0;
    elsif rising_edge(clk) then
        if clk_en = '1' then
            reset_act_cnt <= (reset_act_cnt + 1) mod 6;
        end if;
    end if;
end process;

display_en <= '1' when reset_act_cnt = 0 and clk_en='1' else
              '0';
Reset_Led_internal <= '1' when reset_act_cnt = 0 else
                      '0';

Reset_Led <= Reset_Led_internal;
-- nSelDig Logic ---------------------------------------

-- Display select logic
process(nReset, clk)
    variable cnt : natural range 0 to 5 := 0;
begin
    if nReset = '0' then
        cnt := 0;
    elsif rising_edge(clk) then
        if display_en = '1' then
            cnt := (cnt + 1) mod 6;
        end if;
    end if;

    selDig_internal <= cnt;

end process;

-- not (one hot) conversion
ONE_HOT: for I in nSelDig'range generate
    nSelDig_internal(I) <= '0' when (selDig_internal = I) else
                           '1';
end generate;

-- Output of nSelDig (we do not want to reset and drive at the same time)
nSelDig <= nSelDig_internal when Reset_Led_internal='0' else
           (others => '1');

-- selSeg logic (convert register to correct signal, async) -------------

-- Digit extraction from register
DIG_LOOKUP: for I in number_array_type'range generate
    selSeg_array(I) <= seg7Lookup(to_integer(unsigned(num_array_reg(I)))) & mask_reg(I) when RTC='0' else
                       seg7Lookup(to_integer(unsigned(RTC_array_reg(I)))) & mask_RTC(I);
end generate;

-- For some reason the order is inverted
gen: for i in 0 to selSeg'high generate
    selSeg(i) <= selSeg_array(selDig_internal)(selSeg'high-i);
end generate;

-- RTC PART
process(nReset, clk)
    -- We want to reach 1kHz (diminution factor of ~50000)
    variable cnt : natural range 0 to 500000-1 := 0;
    variable prop: boolean;
begin


    if nReset = '0' then
        cnt := 0;
    elsif rising_edge(clk) then
        cnt := (cnt + 1) mod 500000;

        if cnt = 500000-1 then
            prop := true;

            for I in 0 to 5 loop
                if prop = true then
                    if to_integer(unsigned(RTC_array_reg(I))) = carry_RTC(I) then
                        RTC_array_reg(I) <= (others => '0');
                    else
                        RTC_array_reg(I) <= std_logic_vector(unsigned(RTC_array_reg(I)) + 1);
                        prop := false;
                    end if;
                end if;
            end loop;

        end if;
    end if;
end process;
--Avalon slave write to registers.
process(clk,nReset)
begin
    if nReset = '0' then
        num_array_reg <= (others => (others => '0'));
        mask_reg  <= (others => '0');
        RTC <= '1';
    elsif rising_edge(clk) then
        if write = '1' then
            case Address is
                when "000" => mask_reg <= writedata(5 downto 0);
                when others=>
                    if (to_integer(unsigned(Address)) <= 6+1) then
                       num_array_reg(to_integer(unsigned(Address))-1) <= writedata(4 downto 0);
                    elsif (to_integer(unsigned(Address)) = 8) then
                        RTC <= writedata(0);
                    end if;
            end case;
        end if;
    end if;
end process;

--Avalon slave read from registers.
process(clk)
begin
    if rising_edge(clk) then
        readdata <= (others=>'0');
        if read = '1' then
            case address is
                when "000" => readdata(5 downto 0) <= mask_reg;
                when others=>
                    if (to_integer(unsigned(Address)) <= 6+1) then
                       readdata(4 downto 0) <= num_array_reg(to_integer(unsigned(Address))-1);
                    elsif (to_integer(unsigned(Address)) = 8) then
                        readdata(0) <= RTC;
                    end if;
            end case;
        end if;
    end if;
end process;

end comp;
