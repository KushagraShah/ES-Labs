
--============================================================================
--! @file debay_tb.vhdl
--============================================================================
--! Standard library
library ieee;
library std;
--! Standard packages
use std.env.all;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;
use ieee.std_logic_textio.all;
use ieee.math_real.all;

entity debay_tb is
end debay_tb;

architecture rtl of debay_tb is

constant clock_period : time := 20 ns;

signal clk    : std_logic := '0';
signal rst_n  : std_logic := '1';

signal acq_pixeldata : std_logic_vector(4 downto 0);
signal acq_row_even : std_logic;
signal acq_valid : std_logic;

signal end_rgb_pixeldata_x2 : std_logic_vector(31 downto 0);
signal end_write : std_logic;

component debay is
	port(
		clk : in std_logic;
		rst_n : in std_logic;

        acq_pixeldata : in std_logic_vector(4 downto 0);
		acq_row_even : in std_logic;
		acq_valid : in std_logic;

		end_rgb_pixeldata_x2 : out std_logic_vector(31 downto 0);
        end_write : out std_logic
	);
end component;

begin

dut: debay
    port map(
        clk => clk,
        rst_n => rst_n,

        acq_pixeldata => acq_pixeldata,
		acq_row_even => acq_row_even,
		acq_valid => acq_valid,

		end_rgb_pixeldata_x2 => end_rgb_pixeldata_x2,
        end_write => end_write
    );

p_clock :process
    begin
    clk <= '0';
    wait for clock_period/2;
    clk <= '1';
    wait for clock_period/2;
end process;

p_stim: process
    variable cnt : unsigned(4 downto 0) := (others => '0') ;
begin
    acq_pixeldata <= std_logic_vector(cnt);
    acq_row_even <= '1';
    acq_valid <= '0';
    rst_n <= '1';

    wait for clock_period;
    rst_n <= '0';
    wait for clock_period;
    rst_n <= '1';
    wait for clock_period;

    -- recieve the frame;
    for I in 0 to 1 loop
        -- recieve a row
        for J in 0 to 639 loop
            acq_valid <= '1';
            acq_pixeldata <= std_logic_vector(cnt);
            cnt := cnt + 1;
            wait for clock_period;
        end loop;
        acq_row_even <= not acq_row_even;
    end loop;

    std.env.finish;
end process;

CLOCK: process
begin
    wait for clock_period/2;
    clk <= not clk;
end process;

end rtl;
