-- File 			: LCD_controller_top.vhd
-- Entity		: LCD_controller_top(comp)
-- Description : Top-level entity for the LT24 controller. Instantiates and
--						connects submodules.
-- Author		: Vassili Cruchet
-- Date			: December 2020
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
LIBRARY altera_mf;
USE altera_mf.altera_mf_components.all;

entity LCD_controller_top is
	port (
		clk 		: in std_logic; -- main clock
		nReset	: in std_logic; -- active-low reset

		-- Avalon Slace (AS) interface
		AS_address			: in std_logic_vector(2 downto 0);
		AS_write 			: in std_logic;
		AS_writedata		: in std_logic_vector(31 downto 0);
		AS_read 				: in std_logic;
		AS_readdata			: out std_logic_vector(31 downto 0);
		AS_waitrequest 	: out std_logic;

		-- Avalon Master (AM) interface
		AM_address 					: out std_logic_vector(31 downto 0);
		AM_burstcount				: out std_logic_vector(6 downto 0);
		AM_read 						: out std_logic;
		AM_readdatavalid			: in std_logic;
		AM_readdata 				: in std_logic_vector(31 downto 0);
		AM_waitrequest 			: in std_logic;

		-- Conduit to LT24 peripheral
		LCD_CS_N 	: out std_logic;
		LCD_RS 		: out std_logic;
		LCD_WR_N		: out std_logic;
		LCD_RD_N 	: out std_logic;
		LCD_data 	: out std_logic_vector(15 downto 0)
		);
end entity LCD_controller_top;

architecture comp of LCD_controller_top is
	-----------------------------------------------------------------------------
	-- FIFO component -----------------------------------------------------------
	component FIFO_LCD
		port(
			aclr		: IN STD_LOGIC ;
			clock		: IN STD_LOGIC ;
			data		: IN STD_LOGIC_VECTOR (31 DOWNTO 0);
			rdreq		: IN STD_LOGIC ;
			wrreq		: IN STD_LOGIC ;
			almost_empty		: OUT STD_LOGIC ;
			almost_full		: OUT STD_LOGIC ;
			empty		: OUT STD_LOGIC ;
			full		: OUT STD_LOGIC ;
			q		: OUT STD_LOGIC_VECTOR (31 DOWNTO 0);
			usedw		: OUT STD_LOGIC_VECTOR (7 DOWNTO 0)
	);
	end component;

	-----------------------------------------------------------------------------
	-- Internal signals ---------------------------------------------------------
	-- AS_registers <=> LCD_controller interface
	signal LCD_cmd_i 		: std_logic_vector(15 downto 0);
	signal LCD_cmd_d_i 	: std_logic_vector(15 downto 0);
	signal LCD_cmd_en_i 	: std_logic;
	signal LCD_data_en_i	: std_logic;
	signal LCD_ack_i 		: std_logic;
	-- AS_registers <=> master_control
	signal AM_go_i			: std_logic;
	signal AM_stop_i		: std_logic;
	signal AM_pause_i	 	: std_logic;
	signal AM_done_i	 	: std_logic;
	signal AM_busy_i	 	: std_logic;
	signal AM_rd_add_i 	: std_logic_vector(31 downto 0);
	signal AM_rd_len_i	: std_logic_vector(31 downto 0);
	signal AM_burstcount_i : std_logic_vector(6 downto 0);
	-- master_control <=> FIFO_LCD
	signal FIFO_data_i 	: std_logic_vector(31 downto 0);
	signal FIFO_wrreq_i	: std_logic;
	signal FIFO_full_i	: std_logic;
	signal FIFO_al_full_i : std_logic;
	-- LCD_controller <=> FIFO_LCD
	signal FIFO_q_i 		: std_logic_vector(31 downto 0);
	signal FIFO_empty_i	: std_logic;
	signal FIFO_al_empty_i : std_logic;
	signal FIFO_rdreq_i	: std_logic; 
	-- FIFO reset and used word
	signal Rst 				: std_logic;
	signal FIFO_usedw_i 	: std_logic_vector(7 downto 0);

begin
	Rst <= not nReset;

	-----------------------------------------------------------------------------
	-- Instantiate and connect sub-modules
	AS_REGISTERS : entity work.AS_registers
	port map (
		clk 		=> clk,
		nReset	=> nReset,
		LCD_cmd 		=> LCD_cmd_i,
		LCD_cmd_d 	=> LCD_cmd_d_i,
		LCD_cmd_en	=> LCD_cmd_en_i,
		LCD_data_en => LCD_data_en_i,
		LCD_ack 		=> LCD_ack_i,
		AM_ctl_go 		=> AM_go_i,
		AM_ctl_stop		=> AM_stop_i,
		AM_ctl_pause 	=> AM_pause_i,
		AM_stat_done 	=> AM_done_i,
		AM_stat_busy 	=> AM_busy_i,
		AM_rd_add		=> AM_rd_add_i,
		AM_rd_len		=> AM_rd_len_i,
		AM_burstcount 	=> AM_burstcount_i,
		address			=> AS_address,
		write 			=> AS_write,
		writedata		=> AS_writedata,
		read 				=> AS_read,
		readdata			=> AS_readdata,
		waitrequest 	=> AS_waitrequest);

	-----------------------------------------------------------------------------

	MASTER_CONTROL : entity work.master_control
	port map (
		clk 		=> clk,
		nReset	=> nReset,
		go 		=> AM_go_i,
		stop 		=> AM_stop_i,
		pause 	=> AM_pause_i,
		done 		=> AM_done_i,
		busy 		=> AM_busy_i,
		in_length 		=> AM_rd_len_i,
		in_address		=> AM_rd_add_i,
		in_burstcount 	=> AM_burstcount_i,
		FIFO_data 		=> FIFO_data_i,
		FIFO_wrreq 		=> FIFO_wrreq_i,
		FIFO_full		=> FIFO_full_i,
		FIFO_al_full 	=> FIFO_al_full_i,
		address 					=> AM_address,
		burstcount				=> AM_burstcount,
		read 						=> AM_read,
		readdatavalid			=> AM_readdatavalid,
		readdata 				=> AM_readdata,
		waitrequest 			=> AM_waitrequest
		);

	-----------------------------------------------------------------------------

	LCD_CONTROLLER : entity work.LCD_controller
	port map (
		clk 			 => clk,
		nReset	 	 => nReset,
		wr_cmd_en 	 => LCD_cmd_en_i, 
		wr_data_en   => LCD_data_en_i,	
		wr_ack 		 => LCD_ack_i,
		command 		 => LCD_cmd_i,
		command_data => LCD_cmd_d_i,
		FIFO_data 	 => FIFO_q_i,
		FIFO_empty	 => FIFO_empty_i,
		FIFO_al_empty => FIFO_al_empty_i,
		FIFO_rdreq 	 => FIFO_rdreq_i,
		LCD_CS_N 	 => LCD_CS_N,
		LCD_RS 		 => LCD_RS,
		LCD_WR_N		 => LCD_WR_N,
		LCD_RD_N 	 => LCD_RD_N,
		LCD_data 	 => LCD_data
		);

	-----------------------------------------------------------------------------

	FIFO : FIFO_LCD PORT MAP (
		aclr	 => Rst,
		clock	 => clk,
		data	 => FIFO_data_i,
		rdreq	 => FIFO_rdreq_i,
		wrreq	 => FIFO_wrreq_i,
		almost_empty	=> FIFO_al_empty_i,
		almost_full	 	=> FIFO_al_full_i,
		empty	 => FIFO_empty_i,
		full	 => FIFO_full_i,
		q		 => FIFO_q_i,
		usedw	 => FIFO_usedw_i
	);

end architecture comp;