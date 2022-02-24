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

entity dma_tb is
end dma_tb;

--============================================================================
-- ARCHITECTURE DECLARATION
--============================================================================
architecture rtl of dma_tb is

constant frame_length : integer := 80;
constant burst_count  : integer := 10;
constant burst_bitwidth:integer := 4;

constant clock_period : time := 20 ns;

signal clk    : std_logic := '0';
signal rst_n  : std_logic := '1';

-- end_fifo Interface
signal fifo_RGB2_pixel  : std_logic_vector(31 downto 0);
signal fifo_almost_full : std_logic;
signal fifo_read        : std_logic;

-- Global Controller Interface
signal glob_address : std_logic_vector(31 downto 0);

-- Avalon Interface
signal AM_address      : std_logic_vector(31 downto 0);
signal AM_dataWrite    : std_logic_vector(31 downto 0);
signal AM_burstCount   : std_logic_vector(burst_bitwidth - 1 downto 0);
signal AM_write        : std_logic;
signal AM_waitRequest  : std_logic;

component DMA is
    generic(
        -- Unit of frame_length is in avalon transfer
        frame_length : integer := (320*240)/2;
        -- Must divide evenly screen_width and screen_heigth
        burst_count : integer := 10;
        burst_bitwidth : integer := 4
    );
    port(
        clk : in std_logic;
        nReset : in std_logic;

        -- end_fifo Interface
        fifo_RGB2_pixel  : in  std_logic_vector(31 downto 0);
        fifo_almost_full : in  std_logic;
        fifo_read        : out std_logic;

        -- Global Controller Interface
        glob_address : in std_logic_vector(31 downto 0);

        -- Avalon Interface
        AM_address      : out std_logic_vector(31 downto 0);
        AM_dataWrite    : out std_logic_vector(31 downto 0);
        AM_burstCount   : out std_logic_vector(burst_bitwidth - 1 downto 0);
        AM_write        : out std_logic;
        AM_waitRequest  : in  std_logic
);
end component;

begin

dut: DMA
    generic map(
        frame_length => frame_length,
        burst_count => burst_count
    )
    port map (
        clk => clk,
        nReset => rst_n,

        -- end_fifo Interface
        fifo_RGB2_pixel  => fifo_RGB2_pixel,
        fifo_almost_full => fifo_almost_full,
        fifo_read        => fifo_read,

        -- Global Controller Interface
        glob_address => glob_address,

        -- Avalon Interface
        AM_address      => AM_address,
        AM_dataWrite    => AM_dataWrite,
        AM_burstCount   => AM_burstCount,
        AM_write        => AM_write,
        AM_waitRequest  => AM_waitRequest
);

p_clock :process
    begin
    clk <= '0';
    wait for clock_period/2;
    clk <= '1';
    wait for clock_period/2;
end process;

p_stim: process
    variable cnt : unsigned(31 downto 0) := (others => '0') ;
begin

------------------------------------------------------------------------------
-- Test-setup
------------------------------------------------------------------------------
    cnt := cnt + 1;
    glob_address <= (others => '0');
    fifo_almost_full <= '0';
    fifo_RGB2_pixel <= std_logic_vector(cnt);
    AM_waitRequest <= '0';

    wait for clock_period;
    rst_n <= '0';
    wait for clock_period;
    rst_n <= '1';

    wait for 3*clock_period;
    glob_address <= x"AAAAAAAA";

    wait for 3*clock_period;

    fifo_almost_full <= '1';

    for I in 0 to frame_length/burst_count - 1 loop
        AM_waitRequest <= '1';

        wait for clock_period;

        AM_waitRequest <= '0';

        for J in 0 to burst_count - 1 loop
           wait for clock_period;

           if I = frame_length/burst_count - 1 then
               fifo_almost_full <= '0';
           end if;

           cnt := cnt + 1;
           fifo_RGB2_pixel <= std_logic_vector(cnt);

        end loop;
    end loop;

    wait for 10*clock_period;

    std.env.finish;

end process;

CLOCK: process
begin
    wait for clock_period/2;
    clk <= not clk;
end process;

end rtl;
