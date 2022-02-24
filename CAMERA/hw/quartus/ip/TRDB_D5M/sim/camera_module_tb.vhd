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

entity camera_module_tb is
end camera_module_tb;

--============================================================================
-- ARCHITECTURE DECLARATION
--============================================================================
architecture rtl of camera_module_tb is

--============================================================================
-- SIGNAL DECLARATIONS
--============================================================================
constant clock_period : time := 20 ns;

constant screen_width : natural := 640;
constant screen_height : natural := 480;
constant burst_count : natural := 10;
constant burst_bitwidth : natural := 4;

signal clk    : std_logic := '0';
signal rst_n  : std_logic := '1';

    -- Camera Interface
signal camera_frame_valid : std_logic := '0';
signal camera_line_valid  : std_logic := '0';
signal camera_pixel_data  : std_logic_vector(11 downto 0) := (others => '0');
signal camera_pixclk      : std_logic;

signal AS_address : std_logic_vector(2 downto 0);
signal AS_write : std_logic;
signal AS_read : std_logic;
signal AS_writedata : std_logic_vector(31 downto 0);
signal AS_readdata : std_logic_vector(31 downto 0);

signal AM_address      : std_logic_vector(31 downto 0);
signal AM_dataWrite    : std_logic_vector(31 downto 0);
signal AM_burstCount   : std_logic_vector(burst_bitwidth - 1 downto 0);
signal AM_write        : std_logic;
signal AM_waitRequest  : std_logic;

signal am_write_prev : std_logic;
component camera_module is
    generic(
        screen_width : natural := 640;
        screen_height : natural := 480;
        burst_count : natural := 10;
        burst_bitwidth : natural := 4
    );
	port(
		clk : in std_logic;
		rst_n : in std_logic;

        -- Avalon Slave Interface
        AS_address : in std_logic_vector(2 downto 0);
        AS_write : in std_logic;
        AS_read : in std_logic;
        AS_writedata : in std_logic_vector(31 downto 0);
        AS_readdata : out std_logic_vector(31 downto 0);

        -- Avalon Interface
        AM_address      : out std_logic_vector(31 downto 0);
        AM_dataWrite    : out std_logic_vector(31 downto 0);
        AM_burstCount   : out std_logic_vector(burst_bitwidth - 1 downto 0);
        AM_write        : out std_logic;
        AM_waitRequest  : in  std_logic;

        -- Camera Interface
        camera_pixclk      : in std_logic;
        camera_frame_valid : in std_logic;
        camera_line_valid  : in std_logic;
        camera_pixel_data  : in std_logic_vector(11 downto 0)
);
end component camera_module;

begin

dut: camera_module generic map(
        screen_width => screen_width,
        screen_height => screen_height,
        burst_count => burst_count,
        burst_bitwidth => burst_bitwidth
    )
	port map(
		clk => clk,
		rst_n => rst_n,

        -- Avalon Slave Interface
        AS_address => AS_address,
        AS_write => AS_write,
        AS_read => AS_read,
        AS_writedata => AS_writedata,
        AS_readdata => AS_readdata,

        -- Avalon Interface
        AM_address      => AM_address,
        AM_dataWrite    => AM_dataWrite,
        AM_burstCount   => AM_burstCount,
        AM_write        => AM_write,
        AM_waitRequest  => AM_waitRequest,

        -- Camera Interface
        camera_pixclk      => camera_pixclk,
        camera_frame_valid => camera_frame_valid,
        camera_line_valid  => camera_line_valid,
        camera_pixel_data  => camera_pixel_data
);

p_clock :process
    begin
    clk <= '0';
    wait for clock_period/2;
    clk <= '1';
    wait for clock_period/2;
end process;

p_pixclock : process
begin
    wait for clock_period/4;
    while true loop
        camera_pixclk <= '0';
        wait for clock_period/2;
        camera_pixclk <= '1';
        wait for clock_period/2;
    end loop;
end process;

p_stim: process
    variable cnt : unsigned(4 downto 0) := (others => '0') ;
begin

    camera_line_valid <= '0';
    camera_frame_valid <= '0';
    camera_pixel_data <= (others => '0');

    AS_address <= (others => '0');
    AS_write <= '0';
    AS_read <= '0';
    AS_writedata <= (others => '0');


    wait for clock_period/2;
    rst_n <= '0';
    wait for clock_period;
    rst_n <= '1';

    wait for clock_period/2;

    wait for 3*clock_period;
    AS_address <= (others => '0');
    AS_write <= '1';
    wait for clock_period;
    AS_write <= '0';

    wait until rising_edge(camera_pixclk);
    wait for 2*clock_period;
    camera_frame_valid <= '0';

    wait for clock_period;
    camera_frame_valid <= '1';

    wait for clock_period;

    for J in 0 to 1 loop
        for I in 0 to 639 loop
            camera_line_valid <= '1';
            camera_pixel_data <= std_logic_vector(cnt) & "0000000";
            cnt := cnt + 1;
            wait for clock_period;
        end loop;

        camera_line_valid <= '0';
        wait for clock_period;
    end loop;
    std.env.finish;
end process;

waitreq: process(clk)

begin
    if rising_edge(clk) then
        am_write_prev <= AM_write;
    end if;
end process;

AM_waitRequest <= '1' when am_write_prev = '0' and AM_write = '1' else
                  '0';

end rtl;
