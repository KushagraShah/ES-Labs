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

entity global_controller_tb is
end global_controller_tb;

--============================================================================
-- ARCHITECTURE DECLARATION
--============================================================================
architecture rtl of global_controller_tb is

--============================================================================
-- SIGNAL DECLARATIONS
--============================================================================
constant clock_period : time := 20 ns;

signal clk    : std_logic := '0';
signal rst_n  : std_logic := '1';


    -- Avalon Interface
signal AS_address : std_logic_vector(2 downto 0);
signal AS_write : std_logic;
signal AS_read : std_logic;

signal AS_writedata : std_logic_vector(31 downto 0);
signal AS_readdata : std_logic_vector(31 downto 0);

    -- Acquisition Interface
signal acq_start : std_logic;

    -- DMA Interface
signal dma_address : std_logic_vector(31 downto 0);

    -- System Interface
signal system_busy : std_logic;

--============================================================================
-- COMPONENT DECLARATIONS
--============================================================================
------------------------------------------------------------------------------
--! The design under test
------------------------------------------------------------------------------
component global_controller is port(
    clk : in std_logic;
    nReset : in std_logic;

    -- Avalon Interface
    AS_address : in std_logic_vector(2 downto 0);
    AS_write : in std_logic;
    AS_read : in std_logic;

    AS_writedata : in std_logic_vector(31 downto 0);
    AS_readdata : out std_logic_vector(31 downto 0);

    -- Acquisition Interface
    acq_start : out std_logic;

    -- DMA Interface
    dma_address : out std_logic_vector(31 downto 0);

    -- System Interface
    system_busy : in std_logic
);
end component;

begin

--============================================================================
-- COMPONENT INSTANTIATIONS
--============================================================================

------------------------------------------------------------------------------
--! The design under test
------------------------------------------------------------------------------
dut: global_controller port map(
    clk => clk,
    nReset => rst_n,

    -- Avalon Interface
    AS_address => AS_address,
    AS_write => AS_write,
    AS_read => AS_read,

    AS_writedata => AS_writedata,
    AS_readdata => AS_readdata,

    -- Acquisition Interface
    acq_start => acq_start,

    -- DMA Interface
    dma_address => dma_address,

    -- System Interface
    system_busy => system_busy
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

    AS_address <= (others => '0');
    AS_write <= '0';
    AS_read <= '0';
    AS_writedata <= (others => '0');

    system_busy <= '0';

    wait for clock_period/2;
    rst_n <= '0';
    wait for clock_period;
    rst_n <= '1';

    wait for clock_period/2;

    wait for 3*clock_period;
    AS_write <= '1';
    AS_writedata <= std_logic_vector(to_unsigned(16#AAAA#, AS_writedata'length));
    AS_address <= "100";

    wait for clock_period;
    AS_write <= '0';
    AS_writedata <= (others => '0');
    AS_address <= (others => '0');

    wait for 2*clock_period;
    AS_address <= "100";
    AS_read <= '1';

    wait for clock_period;
    AS_address <= "000";
    AS_read <= '0';
    AS_write <= '1';

    wait for clock_period;
    AS_write <= '0';
    wait for 8*clock_period;
    std.env.finish;
end process;

end rtl;
