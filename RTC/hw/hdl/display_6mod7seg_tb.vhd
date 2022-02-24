--============================================================================
--! @file display_6mod7seg_tb.vhdl
--============================================================================
--! Standard library
library ieee;
library std;
--! Standard packages
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use std.env.finish;
--============================================================================
-- ENTITY DECLARATION FOR TEST_CORE_DEFAULT
--============================================================================
entity display_6mod7seg_tb is
end display_6mod7seg_tb;

--============================================================================
-- ARCHITECTURE DECLARATION
--============================================================================
architecture rtl of display_6mod7seg_tb is

--============================================================================
-- TYPE AND CONSTANT DECLARATIONS
--============================================================================
constant clk_period : time := 20 ns;

--============================================================================
-- SIGNAL DECLARATIONS
--============================================================================
signal clk    : std_logic := '0';
signal rst_n  : std_logic := '1';


signal address : std_logic_vector(2 downto 0);
signal write : std_logic;
signal read : std_logic;

signal writedata : std_logic_vector(7 downto 0);
signal readdata : std_logic_vector(7 downto 0);

--External interface(i.e.conduit).
signal selSeg : std_logic_vector(7 downto 0);
signal nSelDig: std_logic_vector(5 downto 0);
signal Reset_Led: std_logic;
--============================================================================
-- COMPONENT DECLARATIONS
--============================================================================
------------------------------------------------------------------------------
--! The design under test
------------------------------------------------------------------------------

component display_6mod7seg is
    port(
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
end component;

--============================================================================
-- ARCHITECTURE BEGIN
--============================================================================
begin

--============================================================================
-- COMPONENT INSTANTIATIONS
--============================================================================

------------------------------------------------------------------------------
--! The design under test
------------------------------------------------------------------------------
dut: display_6mod7seg
    port map(
        clk     => clk,
        nReset  => rst_n,
        --Internalin terface(i.e.Avalonslave).
        address => address,
        write   => write,
        read    => read,

        writedata   => writedata,
        readdata    => readdata,

        --External interface(i.e.conduit).
        selSeg      => selSeg,
        nSelDig     => nSelDig,
        Reset_Led   => Reset_Led
);

--============================================================================
--============================================================================
--  TEST PROCESSS
--! The test described in the header is executed in this process.
--============================================================================
p_stim: process

begin

------------------------------------------------------------------------------
-- Test-setup
------------------------------------------------------------------------------

    read <= '0';
    write <= '0';
    writedata <= (others => '0');

    wait for clk_period;
    rst_n <= '0';

    wait for clk_period;

    rst_n <= '1';

    wait for clk_period;

    write <= '1';
    address <= std_logic_vector(to_unsigned(1,address'length));
    writedata <= std_logic_vector(to_unsigned(8,writedata'length));

    wait for clk_period;

    write <= '1';
    address <= std_logic_vector(to_unsigned(2,address'length));
    writedata <= std_logic_vector(to_unsigned(1,writedata'length));

    wait for clk_period;
    write <= '0';

    wait;
end process;

CLOCK: process
begin
    wait for clk_period/2;
    clk <= not clk;
end process;

P_END: process
begin
    wait for 60000*clk_period;
    std.env.finish;
end process;

end rtl;
--============================================================================
-- ARCHITECTURE END
--============================================================================
