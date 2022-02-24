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
constant custom : boolean := false;
constant horiz : boolean := true;
constant square : boolean := false;
constant square_size : integer := 64;
constant green : boolean := true;
constant green_color : integer := 31;
constant red   : boolean := true;
constant red_color   : integer := 31;
constant blue  : boolean := true;
constant blue_color : integer  :=31;


constant screen_width : natural := 160;
constant screen_height : natural := 120;
constant burst_count : natural := 2;
constant burst_bitwidth : natural := 10;

signal clk    : std_logic := '0';
signal rst_n  : std_logic := '1';

    -- Camera Interface
signal camera_frame_valid : std_logic := '0';
signal camera_line_valid  : std_logic := '0';
signal camera_pixel_data  : std_logic_vector(11 downto 0) := (others => '0');
signal camera_trigger     : std_logic;
signal camera_pixclk      : std_logic;

signal AS_address : std_logic_vector(3 downto 0);
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

file output : TEXT open WRITE_MODE is "out.ppm";


signal cnt : unsigned(4 downto 0) := (others => '0');
signal cnt_total : integer := -1;

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
        AS_address : in std_logic_vector(3 downto 0);
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
        camera_trigger      : out std_logic;
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
        camera_trigger     => camera_trigger,
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

    variable out_line : line;
begin

    write(out_line, string'("P3"));
    writeline(output, out_line);
    write(out_line, screen_width/2);
    write(out_line, string'(" "));
    write(out_line, screen_height/2);
    writeline(output, out_line);
    write(out_line, string'("32"));
    writeline(output, out_line);

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

    for J in 0 to screen_height-1 loop
        for I in 0 to screen_width-1 loop
            camera_line_valid <= '1';

            if custom then
                if (J <= 3) and (I >= screen_width-4)then
                    camera_pixel_data <= (others => '1');
                else
                    camera_pixel_data <= (others => '0');
                end if;
            elsif horiz then
                if (J mod 4 = 0) or (J mod 4 = 1) then
                    camera_pixel_data <= (others => '1');
                else
                    camera_pixel_data <= (others => '0');
                end if;
            elsif square then
                if (I >= screen_width/2 - square_size/2) and (I < screen_width/2 + square_size/2) and
                   (J >= screen_height/2- square_size/2) and (J < screen_height/2+ square_size/2) then
                    if green and ((I mod 2 = 0 and J mod 2 = 0) or (I mod 2 = 1 and J mod 2 = 1)) then
                        --camera_pixel_data <= std_logic_vector(cnt) & "0000000";
                        camera_pixel_data <= std_logic_vector(to_unsigned(green_color,5))& "0000000";
                    elsif red and (I mod 2 = 1 and J mod 2 = 0) then
                        --camera_pixel_data <= std_logic_vector(cnt) & "0000000";
                        camera_pixel_data <= std_logic_vector(to_unsigned(red_color,5))& "0000000";
                    elsif blue and (I mod 2 = 0 and J mod 2 = 1) then
                        camera_pixel_data <= std_logic_vector(to_unsigned(blue_color,5))&"0000000";
                        --camera_pixel_data <= std_logic_vector(cnt) & "0000000";
                    end if;
                else
                        camera_pixel_data <= (others => '0');
                end if;
            else
                if green and ((I mod 2 = 0 and J mod 2 = 0) or (I mod 2 = 1 and J mod 2 = 1)) then
                    camera_pixel_data <= std_logic_vector(cnt) & "0000000";
                    --camera_pixel_data <= std_logic_vector(to_unsigned(green_color,5))& "0000000";
                elsif red and (I mod 2 = 1 and J mod 2 = 0) then
                    camera_pixel_data <= std_logic_vector(cnt) & "0000000";
                    --camera_pixel_data <= std_logic_vector(to_unsigned(red_color,5))& "0000000";
                elsif blue and (I mod 2 = 0 and J mod 2 = 1) then
                    --camera_pixel_data <= std_logic_vector(to_unsigned(blue_color,5))&"0000000";
                    camera_pixel_data <= std_logic_vector(cnt) & "0000000";
                else
                    camera_pixel_data <= (others => '0');
                end if;
            end if;
            cnt <= (cnt + 1) mod 32 ;
            cnt_total <= cnt_total  + 1;
            wait for clock_period;
        end loop;
        camera_line_valid <= '0';
        wait for clock_period;
    end loop;
    camera_frame_valid <= '0';
    wait for 100*clock_period;

    std.env.finish;
end process;


recover: process(clk)

    variable out_line : line;
    variable line_valid_prev : std_logic;
begin
    if rising_edge(clk) then


        if AM_write = '1' and AM_waitRequest = '0' then
            write(out_line, to_integer(unsigned(AM_dataWrite(15 downto 11))));
            write(out_line, string'(" "));
            write(out_line, to_integer(unsigned(AM_dataWrite(10 downto 6))));
            write(out_line, string'(" "));
            write(out_line, to_integer(unsigned(AM_dataWrite(4 downto 0))));
            write(out_line, string'(" "));

            write(out_line, to_integer(unsigned(AM_dataWrite(31 downto 27))));
            write(out_line, string'(" "));
            write(out_line, to_integer(unsigned(AM_dataWrite(26 downto 22))));
            write(out_line, string'(" "));
            write(out_line, to_integer(unsigned(AM_dataWrite(20 downto 16))));
            write(out_line, string'(" "));

            writeline(output, out_line);
        end if;

        line_valid_prev := camera_line_valid;
    end if;
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
