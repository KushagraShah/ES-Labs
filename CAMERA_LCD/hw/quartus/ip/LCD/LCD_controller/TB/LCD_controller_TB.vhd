library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
LIBRARY altera_mf;
USE altera_mf.altera_mf_components.all;

entity LCD_controller_tb is	
end entity LCD_controller_tb;

architecture withFIFO of LCD_controller_tb is
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
	-- CONSTANTS ----------------------------------------------------------------
	-- tb
	constant CLK_PER 		: time  := 20 ns; -- 50 MHz clock

	-- FIFO
	constant FIFO_WIDTH 	: positive := 32;
	constant FIFO_DEPTH 	: positive := 256;
	constant FIFO_AL_EMPTY_VAL : positive := 120;
	constant FIFO_AL_FULL_VAL : positive := 64;

	-- DUT
	constant PIX_PER_LINE : positive := 240; -- number of pixels per line in LT24 memory
	
	-----------------------------------------------------------------------------
	-- INTERNAL SIGNALS ---------------------------------------------------------
	signal finished : boolean := false;
	signal clk 		: std_logic;
	signal nRst 	: std_logic;
	signal Rst 		: std_logic;

	-----------------------------------------------------------------------------
	-- DUT signals --------------------------------------------------------------
	-- Control and status signals
	signal wr_cmd_en 	: std_logic;
	signal wr_data_en : std_logic;	
	signal wr_ack 		: std_logic;
	-- Command code and parameters
	signal command 		: std_logic_vector(15 downto 0);
	signal command_data 	: std_logic_vector(15 downto 0);
	-- Conduit to LT24 peripheral
	signal LCD_CS_N 	: std_logic; -- active-low chip select
	signal LCD_RS 		: std_logic; -- D/CX: 0 => command selected, 1 => data selected
	signal LCD_WR_N	: std_logic; -- active-low write signal 
	signal LCD_RD_N 	: std_logic; -- active-low read signal (not used)
	signal LCD_data 	: std_logic_vector(15 downto 0); -- data or command, depending on LCD_RS

	-----------------------------------------------------------------------------
	-- FIFO_LCD signals ---------------------------------------------------------
	signal FIFO_data 		: std_logic_vector(31 downto 0);
	signal FIFO_wrreq 	: std_logic;
	signal FIFO_rdreq 	: std_logic;
	signal FIFO_full		: std_logic;
	signal FIFO_al_full 	: std_logic;
	signal FIFO_q 			: std_logic_vector(31 downto 0);
	signal FIFO_empty 	: std_logic;
	signal FIFO_al_empty : std_logic;
	signal FIFO_usedw		: std_logic_vector(7 downto 0);
	-----------------------------------------------------------------------------

begin
	-----------------------------------------------------------------------------
	-- instantiate DUT and FIFO -------------------------------------------------
	DUT : entity work.LCD_controller
	port map (
		clk 			 => clk,
		nReset	 	 => nRst,
		wr_cmd_en 	 => wr_cmd_en, 
		wr_data_en   => wr_data_en,	
		wr_ack 		 => wr_ack,
		command 		 => command,
		command_data => command_data,
		FIFO_data 	 => FIFO_q,
		FIFO_empty	 => FIFO_empty,
		FIFO_al_empty => FIFO_al_empty,
		FIFO_rdreq 	 => FIFO_rdreq,
		LCD_CS_N 	 => LCD_CS_N,
		LCD_RS 		 => LCD_RS,
		LCD_WR_N		 => LCD_WR_N,
		LCD_RD_N 	 => LCD_RD_N,
		LCD_data 	 => LCD_data
		);

	FIFO : FIFO_LCD PORT MAP (
		aclr	 => Rst,
		clock	 => clk,
		data	 => FIFO_data,
		rdreq	 => FIFO_rdreq,
		wrreq	 => FIFO_wrreq,
		almost_empty	=> FIFO_al_empty,
		almost_full	 	=> FIFO_al_full,
		empty	 => FIFO_empty,
		full	 => FIFO_full,
		q		 => FIFO_q,
		usedw	 => FIFO_usedw
	);

	-----------------------------------------------------------------------------
	-- clock generation ---------------------------------------------------------
	CLK_GEN : process
	begin 
		if not finished then
			CLK <= '1';
			wait for CLK_PER/ 2;
			CLK <= '0';
			wait for CLK_PER / 2;
		else
			wait;
		end if;
	end process CLK_GEN;

	-----------------------------------------------------------------------------
	-- simulation ---------------------------------------------------------------
	SIM : process	
		--------------------------------------------------------------------------
		-- RESET --
		procedure async_reset is
		begin
			wait until rising_edge(CLK);
			nRst <= '0' after CLK_PER/4, -- active low
					 '1' after 3*CLK_PER/4;
			Rst <= '1' after CLK_PER/4, -- active low
					 '0' after 3*CLK_PER/4;
			wait until rising_edge(CLK);
		end procedure async_reset;

		--------------------------------------------------------------------------
		--	Write command -------------------------------------------------------
		procedure wr_cmd(	constant cmd : unsigned(15 downto 0) ) is
		begin
			wait until rising_edge(clk);
			if wr_ack = '0' then
				wait until wr_ack = '1';
			else 
				wr_cmd_en	 <= '1';
				command 		 <= std_logic_vector(cmd);
				wait until rising_edge(clk);
				wr_cmd_en	 <= '0';
				wait until wr_ack = '1';

			end if;
		end procedure wr_cmd;

		--------------------------------------------------------------------------
		-- Write command data ----------------------------------------------------
		procedure wr_cmd_d( constant cmd_d : unsigned(15 downto 0) ) is
		begin
			wait until rising_edge(clk);
			if wr_ack = '0' then
				wait until wr_ack = '1';
			else 
				wr_data_en	 <= '1';
				command_data <= std_logic_vector(cmd_d);
				wait until rising_edge(clk);
				wr_data_en	 <= '0';
				wait until wr_ack = '1';
			end if;
		end procedure wr_cmd_d;

		--------------------------------------------------------------------------
		-- FILL FIFO -------------------------------------------------------------
		procedure fill_FIFO( constant N_words : positive) is
			variable word : unsigned(31 downto 0) := to_unsigned(16#0BCDFFFF#,32);
		begin
			FIFO_data <= std_logic_vector(word);
			wait for CLK_PER/10;
			FIFO_wrreq <= '1';
			for I in 0 to N_words loop
				word := word - 1;
				wait until rising_edge(clk);
				FIFO_data <= std_logic_vector(word);
			end loop;
			wait until rising_edge(clk);
			FIFO_wrreq <= '0';
			wait until rising_edge(clk);
		end procedure fill_FIFO;
		--------------------------------------------------------------------------

	begin
		--------------------------------------------------------------------------
		-- default values
		nRst 			 <= '1';
		Rst 			 <= '0';
		wr_cmd_en	 <= '0';
		wr_data_en 	 <= '0';
		command 		 <= (others => '0');
		command_data <= (others => '0');
		FIFO_wrreq 	 <= '0';
		FIFO_data 	 <= (others => '0');

		--------------------------------------------------------------------------
		-- simulation
		async_reset;

		
		wr_cmd(X"002C"); -- start display transfer
		fill_FIFO(PIX_PER_LINE/2);
		if wr_ack = '0' then
			wait until wr_ack = '1';
		end if;
		wr_cmd(X"0036");
		wr_cmd_d(X"00EF");

		wait for 2*CLK_PER;
		finished <= true;

		wait;
	end process SIM;
end architecture withFIFO;