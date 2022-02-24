library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity camera_module is
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
        camera_trigger     : out std_logic;
        camera_pixel_data  : in std_logic_vector(11 downto 0)

);
end camera_module;

architecture arch_camera_module of camera_module is

component global_controller is
    port(
        clk : in std_logic;
        nReset : in std_logic;

        -- Avalon Interface
        AS_address : in std_logic_vector(3 downto 0);
        AS_write : in std_logic;
        AS_read : in std_logic;

        AS_writedata : in std_logic_vector(31 downto 0);
        AS_readdata : out std_logic_vector(31 downto 0);

        -- Acquisition Interface
        acq_start : out std_logic;
        acq_start_done : in std_logic;

        -- DMA Interface
        dma_address : out std_logic_vector(31 downto 0);

        -- System Interface
        system_busy : in std_logic;
        end_fifo_busy : in std_logic
    );
end component;

component acq is
    generic (
        screen_width : natural := 640
    );
    port(
        clk : in std_logic;
        nReset : in std_logic;

        -- Camera Interface
        camera_frame_valid : in std_logic;
        camera_line_valid  : in std_logic;
        camera_trigger : out std_logic;
        camera_pixel_data  : in std_logic_vector(11 downto 0);

        -- Debayerization Interface
        deb_row_even : out std_logic;
        deb_valid    : out std_logic;
        deb_pixel_data: out std_logic_vector(11 downto 0);

        -- Global Controller Interface
        glob_start :  in std_logic;
        glob_start_done : out std_logic;
        glob_busy  : out std_logic;

        -- System Interface
        sys_soft_rst : out std_logic
    );
end component;

component debay is
	port(
		clk : in std_logic;
		rst_n : in std_logic;

        acq_pixeldata : in std_logic_vector(4 downto 0);
		acq_row_even : in std_logic;
		acq_valid : in std_logic;

		end_rgb_pixeldata_x2 : out std_logic_vector(31 downto 0);
        end_write : out std_logic;

        sys_soft_rst : in std_logic
	);
end component;

component end_fifo is
	port(
        aclr        : in std_logic := '0';
		data		: in std_logic_vector (31 downto 0);
		rdclk		: in std_logic ;
		rdreq		: in std_logic ;
		wrclk		: in std_logic ;
		wrreq		: in std_logic ;
		q		: out std_logic_vector (31 downto 0);
		rdempty		: out std_logic ;
		rdusedw		: out std_logic_vector (7 downto 0)
	);
end component;

component dma is
    generic(
        -- Unit of frame_length is in avalon transfer
        frame_length : integer := (320*240)/2;
        -- Must divide evenly screen_width and screen_height
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
        AM_waitRequest  : in  std_logic;

        -- System Interface
        sys_soft_rst : in std_logic
    );
end component;

signal glob2acq_start : std_logic;
signal glob2dma_address: std_logic_vector(31 downto 0);
signal system_busy : std_logic;

signal acq2sys_soft_rst : std_logic;
signal acq2glob_start_done : std_logic;
signal acq2deb_row_even : std_logic;
signal acq2deb_valid : std_logic;
signal acq2deb_pixel_data : std_logic_vector(11 downto 0);
signal acq_busy : std_logic;

signal deb2end_rgb_pixel_data_x2 : std_logic_vector(31 downto 0);
signal deb2end_write : std_logic;

signal end2dma_RGB_pixel_data_x2 : std_logic_vector(31 downto 0);
signal end2dma_almost_full : std_logic;
signal dma2end_read : std_logic;

signal end_empty : std_logic;
signal end_usage : std_logic_vector(7 downto 0);


begin

GLOB_CTRL_INST: global_controller
port map(
    clk => clk,
    nReset => rst_n,

    -- Avalon Interface
    AS_address => AS_address,
    AS_write => AS_write,
    AS_read => AS_read,
    AS_writedata => AS_writedata,
    AS_readdata => AS_readdata,

    -- Acquisition Interface
    acq_start => glob2acq_start,
    acq_start_done => acq2glob_start_done,

    -- DMA Interface
    dma_address => glob2dma_address,

    -- System Interface
    system_busy => system_busy,
    end_fifo_busy => end_empty
);

ACQ_INST: acq generic map(
    screen_width => screen_width

) port map(

    clk => camera_pixclk,
    nReset => rst_n,

    -- Camera Interface
    camera_frame_valid => camera_frame_valid,
    camera_line_valid  => camera_line_valid,
    camera_pixel_data  => camera_pixel_data,
    camera_trigger => camera_trigger,

    -- Debayerization Interface
    deb_row_even => acq2deb_row_even,
    deb_valid    => acq2deb_valid,
    deb_pixel_data => acq2deb_pixel_data,

    -- Global Controller Interface
    glob_start => glob2acq_start,
    glob_start_done => acq2glob_start_done,
    glob_busy => acq_busy,
    sys_soft_rst => acq2sys_soft_rst
);

DEBAY_INST: debay port map(
	clk => camera_pixclk,
	rst_n => rst_n,

    acq_pixeldata => acq2deb_pixel_data(11 downto 7),
	acq_row_even => acq2deb_row_even,
	acq_valid => acq2deb_valid,

	end_rgb_pixeldata_x2 => deb2end_rgb_pixel_data_x2,
    end_write => deb2end_write,
    sys_soft_rst => acq2sys_soft_rst
);

END_FIFO_INST: end_fifo port map(
    aclr => acq2sys_soft_rst,
	data => deb2end_rgb_pixel_data_x2,
	rdclk => clk,
	rdreq => dma2end_read,
	rdempty => end_empty,
	rdusedw => end_usage,

	wrclk => camera_pixclk,
	wrreq => deb2end_write,
	q => end2dma_RGB_pixel_data_x2

);


DMA_INST: dma generic map(
    -- Unit of frame_length is in avalon transfer
    frame_length => (screen_width/2*screen_height/2)/2,
    -- Must divide evenly screen_width and screen_height
    burst_count => burst_count,
    burst_bitwidth => burst_bitwidth
) port map(

    clk => clk,
    nReset => rst_n,

    -- end_fifo Interface
    fifo_RGB2_pixel  => end2dma_RGB_pixel_data_x2,
    fifo_almost_full => end2dma_almost_full,
    fifo_read        => dma2end_read,

    -- Global Controller Interface
    glob_address => glob2dma_address,

    -- Avalon Interface
    AM_address      => AM_address,
    AM_dataWrite    => AM_dataWrite,
    AM_burstCount   => AM_burstCount,
    AM_write        => AM_write,
    AM_waitRequest  => AM_waitRequest,

    sys_soft_rst => acq2sys_soft_rst
);

system_busy <= acq_busy or (not end_empty);

end2dma_almost_full <= '1' when (unsigned(end_usage) >= burst_count) else
                       '0';

end arch_camera_module;
