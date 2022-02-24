-- File 			: master_control.vhd
-- Entity		: master_control(AM)
-- Description : Avalon Master interface to read data in the external DDR3 
-- 					memory and transfer it to the internal FIFO.
-- Author		: Vassili Cruchet
-- Date			: December 2020
--
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity master_control is
	port (
		clk 		: in std_logic; -- main clock
		nReset	: in std_logic; -- active-low reset

		-- Control signals
		go 		: in std_logic;
		stop 		: in std_logic;
		pause 	: in std_logic;

		-- Status signals
		done 		: out std_logic;
		busy 		: out std_logic;
		
		-- Input parameters
		in_length 		: in std_logic_vector(31 downto 0); -- length of the whole transfer (#32bits words)
		in_address		: in std_logic_vector(31 downto 0); -- start address in the DDR3 memory
		in_burstcount 	: in std_logic_vector(6 downto 0);	-- length of each bursttransfer (#32bits words)

		-- FIFO signals
		FIFO_data 		: out std_logic_vector(31 downto 0);
		FIFO_wrreq 		: out std_logic;
		FIFO_full		: in std_logic;
		FIFO_al_full 	: in std_logic;

		-- Avalon Master (AM) interface
		address 					: out std_logic_vector(31 downto 0);
		burstcount				: out std_logic_vector(6 downto 0);
		read 						: out std_logic;
		readdatavalid			: in std_logic;
		readdata 				: in std_logic_vector(31 downto 0);
		waitrequest 			: in std_logic
		);
end entity master_control;

architecture AM of master_control is
	type state_type is (IDLE, BURST_START, BURST_WAIT, BURST_READ, BURST_PAUSE);
	-----------------------------------------------------------------------------
	-- Internal Registers -------------------------------------------------------
	-- AM signals
	signal address_reg, address_next 		: std_logic_vector(31 downto 0);
	
	signal burstcount_out_reg, burstcount_out_next	: std_logic_vector(6 downto 0);
	signal read_reg, read_next					: std_logic;
	-- FIFO signals 
	signal FIFO_wrreq_reg, FIFO_wrreq_next 	: std_logic;
	signal FIFO_data_reg, FIFO_data_next	: std_logic_vector(31 downto 0);
	-- status signals
	signal done_reg, done_next					: std_logic;
	signal busy_reg, busy_next 				: std_logic;
	-- Internal signals
	signal burstcount_reg, burstcount_next	: unsigned(8 downto 0); -- remember the burst length (in #words)
	signal burst_cnt_reg, burst_cnt_next	: unsigned(6 downto 0); -- internal burst transfer counter
	signal word_cnt_reg, word_cnt_next 		: unsigned(16 downto 0); -- internal transfered word counter
	signal start_add_reg, start_add_next 	: unsigned(31 downto 0); -- remember the start address
	signal length_reg, length_next	 		: unsigned(31 downto 0); -- remember the transfer length (in #words)								
	-- FSM states
	signal state_reg, state_next : state_type;

begin
	-----------------------------------------------------------------------------
	-- output signals assignment ------------------------------------------------
	done 			<= done_reg;
	busy 			<= busy_reg;
	FIFO_data 	<= FIFO_data_reg;
	FIFO_wrreq 	<= FIFO_wrreq_reg;
	address 		<= address_reg;
	burstcount	<= burstcount_out_reg;
	read 			<= read_reg;

	-----------------------------------------------------------------------------
	-- synchrone update ---------------------------------------------------------
	process(clk, nReset)
	begin
		if nReset = '0' then -- reset
			address_reg 	<= (others => '0');
			burstcount_reg	<= (others => '0');
			burstcount_out_reg	<= (others => '0');
			read_reg 		<= '0';
			FIFO_data_reg  <= (others => '0');
			FIFO_wrreq_reg <= '0';
			done_reg 		<= '1';
			busy_reg 		<= '0';
			burst_cnt_reg 	<= (others => '0');
			word_cnt_reg 	<= (others => '0');
			start_add_reg 	<= (others => '0');
			length_reg 		<= (others => '0');
			state_reg 		<= IDLE;
		elsif rising_edge(clk) then
			address_reg 	<= address_next after 1 ns; -- artificial 1 ns delay for simulation
			burstcount_reg	<= burstcount_next after 1 ns;
			burstcount_out_reg	<= burstcount_out_next after 1 ns;
			read_reg 		<= read_next after 1 ns;
			FIFO_data_reg	<= FIFO_data_next after 1 ns;
			FIFO_wrreq_reg <= FIFO_wrreq_next after 1 ns;
			done_reg			<= done_next after 1 ns;
			busy_reg 		<= busy_next after 1 ns;
			burst_cnt_reg 	<= burst_cnt_next after 1 ns;
			word_cnt_reg	<= word_cnt_next after 1 ns;
			start_add_reg 	<= start_add_next after 1 ns;
			length_reg 		<= length_next after 1 ns;
			state_reg 		<= state_next after 1 ns;
		end if;
	end process;

	-----------------------------------------------------------------------------
	-- next state logic ---------------------------------------------------------
	NSL : process(state_reg, go, stop, pause, waitrequest, FIFO_al_full, burst_cnt_reg, word_cnt_reg, readdatavalid)
	begin
		-- default assignments
		address_next 		<= address_reg;
		burstcount_next	<= burstcount_reg;
		burstcount_out_next	<= burstcount_out_reg;
		read_next 			<= read_reg;
		FIFO_wrreq_next 	<= FIFO_wrreq_reg;
		FIFO_data_next		<= FIFO_data_reg;
		done_next 			<= done_reg;
		busy_next 			<= busy_reg;
		burst_cnt_next 	<= burst_cnt_reg;
		word_cnt_next		<= word_cnt_reg;
		start_add_next	 	<= start_add_reg;
		length_next 		<= length_reg;
		state_next 			<= state_reg;
		
	case state_reg is
		when IDLE =>
			-- reset fields
			address_next 		<= (others => '0');
			burstcount_next	<= (others => '0');
			burstcount_out_next	<= (others => '0');
			read_next 			<= '0';
			FIFO_data_next 	<= (others => '0');
			FIFO_wrreq_next 	<= '0';
			done_next 			<= '1';
			busy_next 			<= '0';
			burst_cnt_next 	<= (others => '0');
			word_cnt_next		<= (others => '0');
			start_add_next	 	<= (others => '0');
			length_next 		<= (others => '0');

			if go = '1' or word_cnt_reg < length_reg then 
				-- sample parameters
				start_add_next 	<= unsigned(in_address);
				length_next 		<= unsigned(in_length);
				burstcount_next(6 downto 0) 	<= unsigned(in_burstcount);

				-- update status
				done_next <= '0';
				busy_next <= '1';
				state_next <= BURST_START;
			end if;
		--------------------------------------------------------------------------
		when BURST_START =>
			FIFO_wrreq_next 	<= '0';
			if FIFO_al_full = '1' or FIFO_full = '1' then -- wait for FIFO to be empty enough
				state_next <= BURST_START; 
			else -- start burst transfer
				read_next 					<= '1';
				address_next 				<= std_logic_vector(start_add_reg);
				burstcount_out_next 		<= std_logic_vector(burstcount_reg(6 downto 0));
				state_next 					<= BURST_WAIT;
			end if;
		--------------------------------------------------------------------------
		when BURST_WAIT =>
			if waitrequest = '1' then -- wait for slave to deassert waitrequest
				state_next <= BURST_WAIT;
			else -- slave has captured transfer parameters
				read_next 			<= '0'; -- deassert read
				address_next 		<= (others => '0'); -- deassert address
				burstcount_out_next 	<= (others => '0'); -- deassert burstcount_out
				state_next 			<= BURST_READ;
			end if;
		--------------------------------------------------------------------------
		when BURST_READ => 
			if pause = '1' and burst_cnt_reg = 0 then
				FIFO_wrreq_next <= '0'; -- stop the FIFO read
				state_next 		<= BURST_PAUSE;
			elsif readdatavalid = '1' then
				FIFO_wrreq_next <= '1'; 			-- sample data and send it to FIFO
				FIFO_data_next	<= readdata; 	-- at next clock cycle
				burst_cnt_next	<= burst_cnt_reg + 1;
				word_cnt_next 	<= word_cnt_reg + 1;

				if word_cnt_reg = length_reg-1 or (stop = '1' and burstcount_reg = 0) then -- whole transfer finished or stopped
					done_next 			<= '1';
					busy_next 			<= '0';
					state_next 			<= IDLE;
				elsif burst_cnt_reg = burstcount_reg(6 downto 0)-1 then -- one burst done
					start_add_next 	<= start_add_reg + shift_left(burstcount_reg, 2); -- start address for the new burst, burstcount_reg is multiplied by 4 to have byte addresses
					burst_cnt_next 	<= (others => '0');
					word_cnt_next 		<= word_cnt_reg+1;
					state_next 			<= BURST_START;
				end if;
			else
				FIFO_wrreq_next <= '0'; -- stop the FIFO read
				state_next <= BURST_READ; -- wait for valid data
			end if;
		--------------------------------------------------------------------------
		when BURST_PAUSE =>
			if pause = '0' then
				state_next <= BURST_READ;
			else
				state_next <= BURST_PAUSE;
			end if;
		--------------------------------------------------------------------------
		when others => null;
	end case;
	end process;
	
end architecture AM;