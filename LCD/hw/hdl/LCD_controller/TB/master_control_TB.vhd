library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
LIBRARY altera_mf;
USE altera_mf.altera_mf_components.all;

entity master_control_tb is	
end entity master_control_tb;

architecture withFIFO of master_control_tb is
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
	constant BURSTLEN 	: positive := 8; -- length of each bursttransfer (#32bits words)
	constant TRANSFER_L	: positive := 32; -- length of the whole transfer (#32bits words)
	
	-----------------------------------------------------------------------------
	-- INTERNAL SIGNALS ---------------------------------------------------------
	signal finished : boolean := false;
	signal clk 		: std_logic;
	signal nRst 	: std_logic;
	signal Rst 		: std_logic;

	-----------------------------------------------------------------------------
	-- master_control signals ---------------------------------------------------
	-- control
	signal go 		: std_logic;
	signal stop 	: std_logic;
	signal pause 	: std_logic;
	-- status
	signal done 	: std_logic;
	signal busy 	: std_logic;
	-- input parameters
	signal in_length 		: std_logic_vector(31 downto 0);
	signal in_address		: std_logic_vector(31 downto 0);
	signal in_burstcount : std_logic_vector(6 downto 0);
	-- Avalon Master (AM) interface
	signal address 				: std_logic_vector(31 downto 0);
	signal burstcount				: std_logic_vector(6 downto 0);
	signal read 					: std_logic;
	signal readdatavalid			: std_logic;
	signal readdata 				: std_logic_vector(31 downto 0);
	signal waitrequest 			: std_logic;
	
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
	-- instantiate DUT and FIFO ----------------------------------------------------------
	DUT : entity work.master_control
	port map (
		clk 		=> clk,
		nReset	=> nRst,
		go 		=> go,
		stop 		=> stop,
		pause 	=> pause,
		done 		=> done,
		busy 		=> busy,
		in_length 		=> in_length,
		in_address		=> in_address,
		in_burstcount 	=> in_burstcount,
		FIFO_data 		=> FIFO_data,
		FIFO_wrreq 		=> FIFO_wrreq,
		FIFO_full		=> FIFO_full,
		FIFO_al_full 	=> FIFO_al_full,
		address 					=> address,
		burstcount				=> burstcount,
		read 						=> read,
		readdatavalid			=> readdatavalid,
		readdata 				=> readdata,
		waitrequest 			=> waitrequest
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
			wait until rising_edge(CLK);
		end procedure async_reset;

		--------------------------------------------------------------------------
		-- AM go --
		procedure am_go( 	constant len : unsigned(31 downto 0);
								constant address : unsigned(31 downto 0);
								constant burstcount : unsigned(6 downto 0)) is
		begin
			wait until rising_edge(clk);
			go 			<= '1';
			in_length 	<= std_logic_vector(len);
			in_address	<= std_logic_vector(address);
			in_burstcount <= std_logic_vector(burstcount);
			wait until rising_edge(clk);
			go 			<= '0';
			in_length 	<= (others => '0');
			in_address	<= (others => '0');
			in_burstcount <= (others => '0');
		end procedure am_go;

		--------------------------------------------------------------------------
		-- AM pause
		procedure am_pause ( constant WAIT_T : integer) is
		begin 
			wait until rising_edge(clk);
			pause  <= '1';
			wait for WAIT_T*CLK_PER;
			pause <= '0';
		end procedure am_pause;

		--------------------------------------------------------------------------
		-- AM stop
		procedure am_stop is 
		begin 
			wait until rising_edge(clk);
			stop <= '1';
			wait until rising_edge(clk);
			stop <= '0';
		end procedure am_stop;

		--------------------------------------------------------------------------
		-- AS waitrequest
		procedure as_waitreq( constant WAIT_T : integer) is
		begin 
			waitrequest <= '1';
			wait for WAIT_T*CLK_PER;
			waitrequest <= '0';
		end procedure as_waitreq;

		--------------------------------------------------------------------------
		-- AS response
		procedure as_response is
		variable q_val : integer := 100;
		begin
			wait until rising_edge(clk);
			q_val	:= 100;
			readdatavalid <= '1';

			for i in 0 to BURSTLEN-1 loop
				readdata <= std_logic_vector(to_unsigned(q_val, readdata'length));
				q_val 	:= q_val + 1;
				wait until rising_edge(clk);
			end loop;
		end procedure as_response;

		----------------------------------------------------------------------------
		---- LCD READ ACKNOWLEDGE
		--procedure lcd_rdack(constant WAIT_T : in integer) is
		--begin
		--	LCD_ack <= '0';
		--	wait for WAIT_T*CLK_PER;
		--	LCD_ack <= '1';
		--end procedure lcd_rdack;
	begin
		--------------------------------------------------------------------------
		-- default values
		nRst 	<= '1';
		Rst 	<= not nRst;
		go 	<= '0';
		stop 	<= '0';
		pause <= '0';
		in_length 		<= (others => '0');
		in_address		<= (others => '0');
		in_burstcount 	<= (others => '0');
		readdatavalid 	<= '0';
		readdata 		<= (others => '0');
		waitrequest	 	<= '0';	
		FIFO_rdreq 		<= '0';

		--wait for CLK_PER;
		-- reset
		async_reset;

		--------------------------------------------------------------------------
		-- simulation
		am_go(to_unsigned(TRANSFER_L, 32), X"0000_0001", to_unsigned(BURSTLEN, 7)); -- initiates TRANSFER_L/BURSTLEN busrt read
		for I in 0 to TRANSFER_L/BURSTLEN-1 loop
			wait until read = '1';
			if I = 0 then
				as_waitreq(2); -- wait request for 2 clock cycles
			end if;
			as_response;
		end loop;

		wait for 2*CLK_PER;
		

		am_go(to_unsigned(TRANSFER_L, 32), X"0000_0001", to_unsigned(BURSTLEN, 7)); -- initiates TRANSFER_L/BURSTLEN busrt read
		for I in 0 to 2 loop
			wait until read = '1';
			as_response;

			if I = 1 then
				am_pause(15); -- pause for 3 clock cycles
			elsif I = 2 then
				am_stop;
			end if;
		end loop;
		--wait until done = '1';

		wait for 2*CLK_PER;
		finished <= true;

		wait;
	end process SIM;
end architecture withFIFO;