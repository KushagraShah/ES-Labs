library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Latency of the module: 0 cycle

entity global_controller is port(
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
end global_controller;

architecture arch of global_controller is
begin

--Avalon slave write to registers.
process(clk,nReset)
    variable dma_address_internal : std_logic_vector(dma_address'range);
begin
    if nReset = '0' then
        dma_address_internal := (others => '0');
        acq_start <= '0';
        AS_readdata <= (others => '0');

    elsif rising_edge(clk) then
        acq_start <= '0';

        if AS_write = '1' and system_busy = '0' then
            case AS_address is
                when "000" =>
                    acq_start <= '1';
                when "100" =>
                    dma_address_internal := AS_writedata;
                when others =>

            end case;
        elsif AS_read = '1' then
            case AS_address is
                when "000" =>
                    AS_readdata <= (others =>'0');
                    AS_readdata(0) <= system_busy;
                when "100" =>
                    AS_readdata <= dma_address_internal;
                when others => AS_readdata <= (others => '0');
            end case;
        end if;
    end if;
    dma_address <= dma_address_internal;
end process;

end arch;
