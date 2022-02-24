--============================================================================
--! @file acq_tb.vhdl
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

entity acq_tb is
end acq_tb;

--============================================================================
-- ARCHITECTURE DECLARATION
--============================================================================
architecture rtl of acq_tb is

--============================================================================
-- SIGNAL DECLARATIONS
--============================================================================
constant clock_period : time := 20 ns;

signal clk    : std_logic := '0';
signal rst_n  : std_logic := '1';

    -- Camera Interface
signal camera_frame_valid : std_logic := '0';
signal camera_line_valid  : std_logic := '0';
signal camera_pixel_data  : std_logic_vector(11 downto 0) := (others => '0');

    -- Debayerization Interface
signal deb_row_even : std_logic;
signal deb_valid    : std_logic;
signal deb_pixel_data : std_logic_vector(11 downto 0);

    -- Global Controller Interface
signal glob_start : std_logic := '0';
signal glob_busy  : std_logic;
--============================================================================
-- COMPONENT DECLARATIONS
--============================================================================
------------------------------------------------------------------------------
--! The design under test
------------------------------------------------------------------------------
component acq is
    port(
    clk : in std_logic;
    nReset : in std_logic;

    -- Camera Interface
    camera_frame_valid : in std_logic;
    camera_line_valid  : in std_logic;
    camera_pixel_data  : in std_logic_vector(11 downto 0);

    -- Debayerization Interface
    deb_row_even : out std_logic;
    deb_valid    : out std_logic;
    deb_pixel_data: out std_logic_vector(11 downto 0);

    -- Global Controller Interface
    glob_start :  in std_logic;
    glob_busy  : out std_logic
);
end component;

begin

--============================================================================
-- COMPONENT INSTANTIATIONS
--============================================================================

------------------------------------------------------------------------------
--! The design under test
------------------------------------------------------------------------------
dut: acq
    port map(
        -- INTERFACE: Clock
        clk     => clk,
        nReset   => rst_n,

    -- Camera Interface
        camera_frame_valid  => camera_frame_valid,
        camera_line_valid   => camera_line_valid,
        camera_pixel_data   => camera_pixel_data,

    -- Debayerization Interface
        deb_row_even    => deb_row_even,
        deb_valid       => deb_valid,
        deb_pixel_data  => deb_pixel_data,

    -- Global Controller Interface
        glob_start  => glob_start,
        glob_busy   => glob_busy
    );

--============================================================================
--  CLOCK PROCESS
--! Process for generating the clock signal
--============================================================================
p_clock :process
    begin
    clk <= '0';
    wait for clock_period/2;
    clk <= '1';
    wait for clock_period/2;
end process;

--============================================================================
--  TEST PROCESSS
--! The test described in the header is executed in this process.
--============================================================================
p_stim: process
    variable cnt : unsigned(11 downto 0) := (others => '0') ;
begin

------------------------------------------------------------------------------
-- Test-setup
------------------------------------------------------------------------------
    glob_start <= '0';
    camera_line_valid <= '0';
    camera_frame_valid <= '1';
    camera_pixel_data <= (others => '0');

    wait for clock_period/2;
    rst_n <= '0';
    wait for clock_period;
    rst_n <= '1';

    wait for clock_period/2;

    wait for 3*clock_period;
    glob_start <= '1';
    wait for clock_period;
    glob_start <= '0';

    wait for 2*clock_period;
    camera_frame_valid <= '0';

    wait for clock_period;
    camera_frame_valid <= '1';

    wait for clock_period;

    for I in 0 to 639 loop
        camera_line_valid <= '1';
        camera_pixel_data <= std_logic_vector(cnt);
        cnt := cnt + 1;
        wait for clock_period;
    end loop;

    camera_line_valid <= '0';
    wait for clock_period;


    for I in 0 to 639 loop
        camera_line_valid <= '1';
        camera_pixel_data <= std_logic_vector(cnt);
        cnt := cnt + 1;
        wait for clock_period;
    end loop;

end process;

CLOCK: process
begin
    wait for clock_period/2;
    clk <= not clk;
end process;

P_END: process
begin
    wait for 1500*clock_period;
    std.env.finish;
end process;

end rtl;
--============================================================================
-- ARCHITECTURE END
--============================================================================
