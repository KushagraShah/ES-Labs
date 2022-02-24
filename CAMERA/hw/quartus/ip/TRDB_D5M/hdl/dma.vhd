library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


-- If module is desynchro, we can clear when glob_write
entity dma is
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
end dma;

architecture arch of dma is
    constant burst_length_byte : natural := burst_count * 32/8;
    constant frame_length_byte : natural := frame_length * 32/8;

    -- Counts the number of bytes written since beginning of frame transfer
    signal progress_cnt_reg, progress_cnt_next : natural range 0 to frame_length_byte - 1;
    -- Counst the number of transactions in a burst
    signal burst_cnt_reg, burst_cnt_next : integer range 0 to burst_count - 1;

    signal write : std_logic;
begin
    process(clk,nReset)
    begin
        if nReset = '0' then
            progress_cnt_reg <= 0;
            burst_cnt_reg <= 0;

        elsif rising_edge(clk) then
            progress_cnt_reg <= progress_cnt_next;
            burst_cnt_reg <= burst_cnt_next;

        end if;
    end process;

    -- Either we want to start a transfer, or we are in a transfer
    write <= '1' when (fifo_almost_full = '1') or  -- we can send a burst
                      (burst_cnt_reg /= 0) else    -- we are in a burst
             '0';

    burst_cnt_next <= (burst_cnt_reg + 1) mod burst_count when write='1' and (AM_waitRequest='0') else
                      burst_cnt_reg;

    progress_cnt_next <= (progress_cnt_reg + burst_length_byte) mod (frame_length_byte)
                            when (burst_cnt_reg = burst_count - 1)
                         else progress_cnt_reg;

    fifo_read <= write and (not AM_waitRequest);

    AM_write <= write;

    AM_address <= std_logic_vector(unsigned(glob_address) + progress_cnt_reg);

    AM_burstCount <= std_logic_vector(to_unsigned(burst_count,AM_burstCount'length));

    AM_dataWrite <= fifo_RGB2_pixel;
end arch;
