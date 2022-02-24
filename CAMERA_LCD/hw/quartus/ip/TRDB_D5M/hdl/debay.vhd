library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

LIBRARY altera_mf;
USE altera_mf.all;

entity debay is
	port(
		clk : in std_logic;
		rst_n : in std_logic;

        acq_pixeldata : in std_logic_vector(4 downto 0);
		acq_row_even : in std_logic;
		acq_valid : in std_logic;

		end_rgb_pixeldata_x2 : out std_logic_vector(31 downto 0);
        end_write : out std_logic;

        sys_soft_rst : in std_logic
	);
end debay;

architecture arch_debay of debay is

    signal column_even : std_logic;
    signal pix_buff : std_logic_vector(4 downto 0);
    signal RGB_pix, RGB_pix_buff : std_logic_vector (15 downto 0);
    signal RGB_pix_ready : std_logic;
    signal fifo_data_in, fifo_data_out : std_logic_vector(9 downto 0);
    signal fifo_write : std_logic;
    signal fifo_read : std_logic;

    signal cnt : natural range 0 to 3; -- count the pixel row (mod 4)

    component row_fifo is
        port(
            clock		: in std_logic ;
            data		: in std_logic_vector (9 downto 0);
            rdreq		: in std_logic ;
		    sclr		: in std_logic ;
            wrreq		: in std_logic ;
            q		: out std_logic_vector (9 downto 0)
        );
    end component row_fifo;

begin

process(clk, rst_n, acq_valid)
begin
    if(rst_n = '0') then
        cnt <= 0;
        pix_buff <= (others => '0');
        RGB_pix_buff <= (others => '0');
    elsif rising_edge(clk) then
        if sys_soft_rst = '1' then
            cnt <= 0;
        end if;

        if acq_valid = '1' then
            cnt <= (cnt + 1) mod 4;

            if (acq_valid = '1') then
                pix_buff <= acq_pixeldata;
            end if;

            if (RGB_pix_ready = '1') then
                RGB_pix_buff <= RGB_pix;
            end if;
        end if;
    end if;
end process;

column_even <= '1' when (cnt mod 2 = 0) else
               '0';
RGB_pix_ready <= '1' when (cnt = 1) and (acq_row_even = '0') else
                 '0';

fifo_write <= '1' when acq_row_even='1' and (column_even='0') and acq_valid='1' else
              '0';
fifo_read  <= '1' when (acq_row_even='0') and (column_even='0') and acq_valid='1' else
              '0';
fifo_data_in <= acq_pixeldata & pix_buff;

RGB_pix <= fifo_data_out(9 downto 5) &
           std_logic_vector(unsigned('0' & fifo_data_out(4 downto 0)) +
                            unsigned('0' & acq_pixeldata)) &
           pix_buff;

end_rgb_pixeldata_x2 <= RGB_pix & RGB_pix_buff;

end_write <= '1' when (cnt = 3) and (acq_row_even = '0') else
             '0';

debayer_store: row_fifo port map(
    clock => clk,
    data => fifo_data_in,
    rdreq => fifo_read,
    sclr => sys_soft_rst,
    wrreq => fifo_write,
    q => fifo_data_out
);

end arch_debay;
