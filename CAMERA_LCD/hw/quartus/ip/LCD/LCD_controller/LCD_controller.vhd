-- File 			: LCD_controller.vhd
-- Entity		: LCD_controller(I_8080)
-- Description : Generates control signals for the IL9341 chip controlling the 
-- 					LT24 LCD display according to the 8080-I communication 
-- 					protocol.
-- Author		: Vassili Cruchet
-- Date			: December 2020
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity LCD_controller is
	port (
		clk 		: in std_logic; -- main clock
		nReset	: in std_logic; -- active-low reset

		-- Control and status signals
		wr_cmd_en 	: in std_logic;
		wr_data_en  : in std_logic;	
		wr_ack 		: out std_logic;

		-- Command code and parameters
		command 			: in std_logic_vector(15 downto 0);
		command_data 	: in std_logic_vector(15 downto 0);

		-- FIFO signals and data
		FIFO_data 		: in std_logic_vector(31 downto 0);
		FIFO_empty		: in std_logic;
		FIFO_al_empty 	: in std_logic;
		FIFO_rdreq 		: out std_logic;

		-- Conduit to LT24 peripheral
		LCD_CS_N 	: out std_logic; -- active-low chip select
		LCD_RS 		: out std_logic; -- D/CX: 0 => command selected, 1 => data selected
		LCD_WR_N		: out std_logic; -- active-low write signal 
		LCD_RD_N 	: out std_logic; -- active-low read signal (not used)
		LCD_data 	: out std_logic_vector(15 downto 0) -- data or command, depending on LCD_RS
		);
end entity LCD_controller;

architecture I_8080 of LCD_controller is
	type state_type is (IDLE, SEND_CMD, SEND_CMD_D, SEND_PIX_D, FIFO_WAIT, FIFO_RD_REQ); -- states of the FSM

	-----------------------------------------------------------------------------
	-- Constants ----------------------------------------------------------------
	constant PIX_PER_LINE : unsigned(7 downto 0) := to_unsigned(240,8); -- #pixels per line in LT24 memory
	constant CMD_MEM_WRITE : std_logic_vector(15 downto 0) := std_logic_vector(to_unsigned(16#002C#, 16));

	-----------------------------------------------------------------------------
	-- Internal registers and signals -------------------------------------------
	-- output signals
	signal wr_ack_reg, wr_ack_next 				: std_logic;
	signal FIFO_rdreq_reg, FIFO_rdreq_next 	: std_logic;
	signal LCD_CS_N_reg, LCD_CS_N_next 			: std_logic;
	signal LCD_RS_reg, LCD_RS_next		 		: std_logic;
	signal LCD_WR_N_reg, LCD_WR_N_next			: std_logic;
	signal LCD_RD_N_reg, LCD_RD_N_next 			: std_logic;
	signal LCD_data_reg, LCD_data_next 		 	: std_logic_vector(15 downto 0);
	-- internal signal and FSM
	signal state_reg, state_next 					: state_type;
	signal cnt_reg, cnt_next 						: unsigned(7 downto 0); -- 8 bits counter
	signal pix_cnt_reg, pix_cnt_next 			: unsigned(7 downto 0); -- 8 bits pixel counter
	signal FIFO_data_reg, FIFO_data_next 		: std_logic_vector(31 downto 0); -- remember the 32bits word read from FIFO

begin
	-----------------------------------------------------------------------------
	-- output signals assignment
	wr_ack 		 <= wr_ack_reg;
	FIFO_rdreq 	 <= FIFO_rdreq_reg;
	LCD_CS_N 	 <= LCD_CS_N_reg;
	LCD_RS 		 <= LCD_RS_reg;
	LCD_WR_N 	 <= LCD_WR_N_reg;
	LCD_RD_N 	 <= LCD_RD_N_reg;
	LCD_data 	 <= LCD_data_reg;

	-----------------------------------------------------------------------------
	-- synchrone update ---------------------------------------------------------
	process(clk, nReset)
	begin
		if nReset = '0' then -- reset
			wr_ack_reg 		 <= '1';
			FIFO_rdreq_reg  <= '0';
			LCD_CS_N_reg	 <= '1';
			LCD_RS_reg 		 <= '1'; -- default : data
			LCD_WR_N_reg	 <= '1';
			LCD_RD_N_reg	 <= '1';
			LCD_data_reg	 <= (others => '0');
			cnt_reg 			 <= (others => '0');
			pix_cnt_reg 	 <= (others => '0');
			FIFO_data_reg 	 <= (others => '0');
			state_reg 		 <= IDLE;
		elsif rising_edge(clk) then
			wr_ack_reg 		 <= wr_ack_next after 1 ns; -- artificial 1 ns delay for simulation;
			FIFO_rdreq_reg  <= FIFO_rdreq_next after 1 ns;
			LCD_CS_N_reg	 <= LCD_CS_N_next after 1 ns;
			LCD_RS_reg 		 <= LCD_RS_next after 1 ns;
			LCD_WR_N_reg	 <= LCD_WR_N_next after 1 ns;
			LCD_RD_N_reg	 <= LCD_RD_N_next after 1 ns;
			LCD_data_reg	 <= LCD_data_next after 1 ns;
			cnt_reg 			 <= cnt_next after 1 ns;
			pix_cnt_reg 	 <= pix_cnt_next after 1 ns;
			FIFO_data_reg 	 <= FIFO_data_next after 1 ns;
			state_reg 		 <= state_next after 1 ns;
		end if;
	end process;

	-----------------------------------------------------------------------------
	-- next state logic ---------------------------------------------------------
	NSL : process(state_reg, wr_cmd_en, wr_data_en, FIFO_al_empty, cnt_reg, pix_cnt_reg)
	begin
		-- default assignments
		wr_ack_next 		 <= wr_ack_reg;
		FIFO_rdreq_next 	 <= FIFO_rdreq_reg;
		LCD_CS_N_next 		 <= LCD_CS_N_reg;
		LCD_RS_next 		 <= LCD_RS_reg;
		LCD_WR_N_next 		 <= LCD_WR_N_reg;
		LCD_RD_N_next 		 <= LCD_RD_N_reg;
		LCD_data_next 		 <= LCD_data_reg;
		cnt_next 			 <= cnt_reg;
		pix_cnt_next 		 <= pix_cnt_reg;
		FIFO_data_next 	 <= FIFO_data_reg;
		state_next 			 <= state_reg;

	case state_reg is
		when IDLE => 
			if wr_cmd_en = '1' then
				state_next	 <= SEND_CMD;
				wr_ack_next	 <= '0'; -- busy
			elsif wr_data_en = '1' then
				state_next	 <= SEND_CMD_D;
				wr_ack_next	 <= '0'; -- busy
			else
				state_next <= IDLE;
			end if;
		--------------------------------------------------------------------------
		when SEND_CMD => 
			cnt_next <= cnt_reg + 1; -- increment counter
			-- genereate LCD signal to send cmd. The whole write cycle last 4 clk cylcles
			if cnt_reg = 0 then
				LCD_CS_N_next 	 <= '0';
				LCD_RS_next 	 <= '0'; -- command selected
				LCD_WR_N_next 	 <= '0'; -- write request
				LCD_data_next 	 <= command; -- transmit command
			elsif cnt_reg = 1 then
				-- do nothing, signals are held during 2 clk cycles
			elsif cnt_reg = 2 then
				LCD_WR_N_next 	 <= '1'; -- write control pulse low finished
			else
				LCD_CS_N_next 	 <= '1'; -- chip select setup time finished
				LCD_RS_next 	 <= '1'; -- D/CX back to '1'
				LCD_data_next 	 <= (others => '0'); -- release data
				cnt_next 		 <= (others => '0'); -- reset counter

				--state_next	 <= IDLE; -- back to IDLE
				--wr_ack_next	 <= '1'; -- not busy anymore

				if command = CMD_MEM_WRITE then
					state_next	 <= FIFO_WAIT; -- send display data
					wr_ack_next	 <= '1'; -- not busy anymore
				else
					state_next	 <= IDLE; -- back to IDLE
					wr_ack_next	 <= '1'; -- not busy anymore
				end if;
			end if;

		--------------------------------------------------------------------------
		when SEND_CMD_D => 
			cnt_next <= cnt_reg + 1; -- increment counter
			-- genereate LCD signal to send cmd data. The whole write cycle last 4 clk cylcles
			if cnt_reg = 0 then
				LCD_CS_N_next 	 <= '0';
				LCD_RS_next 	 <= '1'; -- data selected
				LCD_WR_N_next 	 <= '0'; -- write request
				LCD_data_next 	 <= command_data; -- transmit command_data
			elsif cnt_reg = 1 then
				-- do nothing, signals are held during 2 clk cycles
			elsif cnt_reg = 2 then
				LCD_WR_N_next 	 <= '1'; -- write control pulse low finished
			else
				LCD_CS_N_next 	 <= '1'; -- chip select setup time finished
				LCD_RS_next 	 <= '1'; -- D/CX back to '1'
				LCD_data_next 	 <= (others => '0'); -- release data
				cnt_next 		 <= (others => '0'); -- reset counter

				state_next	 <= IDLE; -- back to IDLE
				wr_ack_next	 <= '1'; -- not busy anymore
			end if;

		--------------------------------------------------------------------------
		when FIFO_WAIT => 
			if wr_cmd_en = '1' then
				-- a command is recieved, stop waiting
				state_next <= SEND_CMD;
				wr_ack_next <= '0'; -- busy

			elsif FIFO_al_empty = '0' and FIFO_empty = '0' then
				-- start FIFO read and send a whole line
				wr_ack_next <= '0'; -- busy
				state_next  <= FIFO_RD_REQ;

			else -- wait 
				state_next <= FIFO_WAIT;
			end if;

		--------------------------------------------------------------------------
		when FIFO_RD_REQ => 
			FIFO_rdreq_next <= '1';
			FIFO_data_next  <= FIFO_data; -- FIFO is in "show-ahead" mode, thus, data can already be sampled
			state_next		 <= SEND_PIX_D;

		--------------------------------------------------------------------------
		when SEND_PIX_D => 
			cnt_next <= cnt_reg + 1; -- increment counter
			-- generate LCD signals to send display data. 
			-- The whole write cycle last 4 clk cycles and is repeated PIX_PER_LINE times
			if cnt_reg = 0 or cnt_reg = 4 then
				LCD_CS_N_next 	 <= '0'; -- assert chip select
				LCD_RS_next 	 <= '1'; -- data selected
				LCD_WR_N_next 	 <= '0'; -- write request
				
				if cnt_reg = 0 then
					LCD_data_next <= FIFO_data_reg(15 downto 0);
				else -- transmit 1st pixel
				 	LCD_data_next <= FIFO_data_reg(31 downto 16); -- transmit 2nd pixel
				end if;
				FIFO_rdreq_next <= '0'; -- deassert read request on FIFO 

			elsif cnt_reg = 1 or cnt_reg = 5 then
				-- do nothing, signals are held during 2 clk cycles

			elsif cnt_reg = 2 or cnt_reg = 6 then
				LCD_WR_N_next 	 <= '1'; -- write control pulse low finished

			elsif cnt_reg = 3 then -- 1st pixel complete
				LCD_CS_N_next 	 <= '1'; -- chip select setup time finished
				pix_cnt_next <= pix_cnt_reg + 1; -- increment pixel counter

			elsif cnt_reg = 7 then-- 2nd pixel complete
				LCD_CS_N_next 	 <= '1'; -- chip select setup time finished
				cnt_next 	 <= (others => '0'); -- restart counter

				if pix_cnt_reg = PIX_PER_LINE-1 then -- the whole line was sent
					pix_cnt_next	 <= (others => '0');
					LCD_RS_next 	 <= '1'; -- D/CX back to '1'
					LCD_data_next 	 <= (others => '0'); -- release data
					wr_ack_next		 <= '1'; -- not busy anymore
					state_next 		 <= FIFO_WAIT;
				else	
					--FIFO_rdreq_next <= '1'; -- read a new 2pixels word in FIFO
					--FIFO_data_next  <= FIFO_data; -- FIFO is in "show-ahead" mode, thus data can already be sampled
					pix_cnt_next <= pix_cnt_reg + 1;
					state_next 	 <= FIFO_RD_REQ; -- send 2 pixel more again
				end if;
			end if;
		--------------------------------------------------------------------------
		when others => null;
	end case;
	end process;
end architecture I_8080;