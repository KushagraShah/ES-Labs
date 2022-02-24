library ieee;
use ieee.std_logic_1164.all;

-- Latency of the module: 0 cycle

entity acq is
    generic (
        screen_width : natural := 640
    );
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
end acq;

architecture arch of acq is
    type state_t is (idle, ready, even, odd);
    signal state_reg, state_next : state_t;
    signal camera_frame_valid_buff, camera_frame_valid_prev : std_logic;

    signal count_reg, count_next : natural range 0 to screen_width - 1;
begin
    process(clk,nReset)
    begin
        if nReset = '0' then
            count_reg <= 0;
            state_reg <= idle;
        elsif rising_edge(clk) then
            camera_frame_valid_prev <= camera_frame_valid_buff;
            camera_frame_valid_buff <= camera_frame_valid;
            count_reg <= count_next;
            state_reg <= state_next;
       end if;
    end process;

    count_next <= (count_reg + 1) mod screen_width when (camera_line_valid='1' and
                                                        camera_frame_valid='1') else
                  count_reg;

    process(camera_line_valid, camera_frame_valid, glob_start, count_reg, clk)
    begin
            case state_reg is
                when idle =>
                    if glob_start = '1' then
                        state_next <= ready;
                    else
                        state_next <= idle;
                    end if;
                    glob_busy <= '0';
                when ready =>
                    if camera_frame_valid = '1' and camera_frame_valid_prev = '0' then
                        state_next <= even;
                    else
                        state_next <= ready;
                    end if;
                    glob_busy <= '1';
                when even =>
                    if camera_frame_valid = '0' then
                        state_next <= idle;
                    elsif (count_reg = screen_width-1) and (camera_line_valid = '1') then
                        state_next <= odd;
                    else
                        state_next <= even;
                    end if;

                    glob_busy <= '1';
                when odd =>
                    if camera_frame_valid <= '0' then
                        state_next <= idle;
                    elsif (count_reg = screen_width-1) and (camera_line_valid = '1') then
                        state_next <= even;
                    else
                        state_next <= odd;
                    end if;

                    glob_busy <= '1';
            end case;
    end process;

    deb_row_even <= '0' when state_reg=odd else
                    '1';

    deb_valid <= camera_frame_valid and camera_line_valid;

    deb_pixel_data <= camera_pixel_data;
end arch;
