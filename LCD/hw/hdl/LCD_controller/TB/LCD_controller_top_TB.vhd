library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
LIBRARY altera_mf;
USE altera_mf.altera_mf_components.all;

entity LCD_controller_top_tb is	
end entity LCD_controller_top_tb;

architecture simple of LCD_controller_top_tb is
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

	-- REGISTER MAP
	constant ADD_READADDRESS : std_logic_vector(2 downto 0) := "000";
	constant ADD_LENGTH 		 : std_logic_vector(2 downto 0) := "001";
	constant ADD_BURSTCNT	 : std_logic_vector(2 downto 0) := "010";
	constant ADD_STATUS		 : std_logic_vector(2 downto 0) := "011";
	constant ADD_CONTROL		 : std_logic_vector(2 downto 0) := "100";
	constant ADD_LCD_CMD		 : std_logic_vector(2 downto 0) := "101";
	constant ADD_LCD_CMD_D	 : std_logic_vector(2 downto 0) := "110";

-- DUT
	constant BURSTLEN_int 	: positive := 8; -- length of each bursttransfer (#32bits words)
	constant TRANS_L_int	: positive := 320*240/2; -- length of the whole transfer (#32bits words)

	-- COMMANDS AND PARAMETERS
	constant CMD_MEM_WRITE	: std_logic_vector(31 downto 0) := std_logic_vector(to_unsigned(16#2C#,32));
	constant CMD_MEM_ACCESS : std_logic_vector(31 downto 0) := std_logic_vector(to_unsigned(16#36#,32));
	constant MADCTL 			: std_logic_vector(31 downto 0) := std_logic_vector(to_unsigned(16#FE#,32));
	constant TRANSFER_LEN 	: std_logic_vector(31 downto 0) := std_logic_vector(to_unsigned(TRANS_L_int,32));
	constant BURST_LEN		: std_logic_vector(31 downto 0) := std_logic_vector(to_unsigned(BURSTLEN_int,32));
	constant START_ADD 		: std_logic_vector(31 downto 0) := std_logic_vector(to_unsigned(16#1#,32));
	constant CTRL_GO 			: std_logic_vector(31 downto 0) := std_logic_vector(to_unsigned(16#1#,32));
	constant CTRL_STOP	 	: std_logic_vector(31 downto 0) := std_logic_vector(to_unsigned(16#2#,32));
	constant CTRL_PAUSE		: std_logic_vector(31 downto 0) := std_logic_vector(to_unsigned(16#4#,32));
	constant ALL0_32b 		: std_logic_vector(31 downto 0) := (others => '0');
	
	-----------------------------------------------------------------------------
	-- INTERNAL SIGNALS ---------------------------------------------------------
	signal finished : boolean := false;
	signal clk 		: std_logic;
	signal nRst 	: std_logic;

	-----------------------------------------------------------------------------
	-- LCD_controller_top signals -----------------------------------------------
	-- Avalon Master (AM) interface
	signal AM_address 				: std_logic_vector(31 downto 0);
	signal AM_burstcount				: std_logic_vector(6 downto 0);
	signal AM_read 					: std_logic;
	signal AM_readdatavalid			: std_logic;
	signal AM_readdata 				: std_logic_vector(31 downto 0);
	signal AM_waitrequest 			: std_logic;
	-- AS
	signal AS_address 		: std_logic_vector(2 downto 0);
	signal AS_write 			: std_logic;
	signal AS_read 			: std_logic;
	signal AS_waitrequest 	: std_logic;
	signal AS_writedata 		: std_logic_vector(31 downto 0);
	signal AS_readdata		: std_logic_vector(31 downto 0);
	-- Conduit to LT24 peripheral
	signal LCD_CS_N 	: std_logic; -- active-low chip select
	signal LCD_RS 		: std_logic; -- D/CX: 0 => command selected, 1 => data selected
	signal LCD_WR_N	: std_logic; -- active-low write signal 
	signal LCD_RD_N 	: std_logic; -- active-low read signal (not used)
	signal LCD_data 	: std_logic_vector(15 downto 0); -- data or command, depending on LCD_RS
	-----------------------------------------------------------------------------

begin
	-----------------------------------------------------------------------------
	-- instantiate DUT-------------------------------------------------
	DUT : entity work.LCD_controller_top
	port map (
		clk 		 => clk,
		nReset	 => nRst,
		AS_address		 => AS_address,
		AS_write 		 => AS_write,
		AS_writedata	 => AS_writedata,
		AS_read 			 => AS_read,
		AS_readdata		 => AS_readdata,
		AS_waitrequest  => AS_waitrequest,
		AM_address 				 => AM_address,
		AM_burstcount			 => AM_burstcount,
		AM_read 					 => AM_read,
		AM_readdatavalid		 => AM_readdatavalid,
		AM_readdata 			 => AM_readdata,
		AM_waitrequest 		 => AM_waitrequest,
		LCD_CS_N 	 => LCD_CS_N,
		LCD_RS 		 => LCD_RS,
		LCD_WR_N		 => LCD_WR_N,
		LCD_RD_N 	 => LCD_RD_N,
		LCD_data 	 => LCD_data
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
		-- AS WRITE --
		procedure as_wr( 	constant add_in 		: in std_logic_vector(2 downto 0); 
									constant wr_data_in 	: in std_logic_vector(31 downto 0)) is 
		begin
			wait for CLK_PER/10; -- assert signals AFTER rising edge of clk
			AS_address 		<= add_in;
			AS_write 		<= '1';
			AS_writedata 	<= wr_data_in;

			wait until AS_waitrequest = '0';
			wait until rising_edge(CLK); -- hold signal assignments until the next 
												  -- rising edge of CLK so the circuit can see them.												  
			AS_address		<= (others => '0');
			AS_write 		<= '0';
			AS_writedata 	<= (others => '0');
		end procedure as_wr;

		--------------------------------------------------------------------------
		-- AS READ --
		procedure as_rd( constant add_in : in std_logic_vector(2 downto 0)) is
			variable rd_data_out : integer;
		begin
			AS_address 		<= add_in;
			AS_read 			<= '1';

			wait until AS_waitrequest = '0';  -- hold signal assignments until waitrequest is de-asserted
			wait until rising_edge(CLK); -- data avialable at next clk rising edge
			rd_data_out := to_integer(signed(AS_readdata));

			---- display read value
			--if add_in = '0' then
			--	report 	LF & " --- AVALON READ ---" &
			--				LF & " Address = " & std_logic'image(add_in) &
			--				LF & " RegPer  = " & integer'image(rd_data_out);
			--elsif add_in = '1' then
			--	report 	LF & " --- AVALON READ ---" &
			--				LF & " Address = " & std_logic'image(add_in) &
			--				LF & " RegPulseW = " & integer'image(rd_data_out);
			--end if;

			wait until rising_edge(CLK);
			AS_address 		<= (others => '0');
			AS_read 			<= '0';
		end procedure as_rd;

		--------------------------------------------------------------------------
		-- DDR3 response
		procedure DDR3_response is
		variable q_val : integer := 100;
		begin
			wait until rising_edge(clk);
			q_val	:= 100;
			AM_readdatavalid <= '1';

			for i in 0 to BURSTLEN_int-1 loop
				AM_readdata <= std_logic_vector(to_unsigned(q_val, AM_readdata'length));
				q_val 	:= q_val + 1;
				wait until rising_edge(clk);
			end loop;
			AM_readdatavalid <= '0';
		end procedure DDR3_response;
		--------------------------------------------------------------------------
	begin
		--------------------------------------------------------------------------
		-- default value
		nRst 				<= '1';
		AS_address 		<= (others => '0');
		AS_write 		<= '0';
		AS_read 			<= '0';
		AS_writedata 	<= (others => '0');
		AM_readdatavalid <= '0';
		AM_readdata 	<= (others => '0');
		AM_waitrequest <= '0';

		wait for CLK_PER;
		-- reset
		async_reset;

		--------------------------------------------------------------------------
		-- simulation
		as_wr(ADD_READADDRESS, START_ADD);
		as_wr(ADD_LENGTH, TRANSFER_LEN);
		as_wr(ADD_BURSTCNT, BURST_LEN);
		as_wr(ADD_LCD_CMD, CMD_MEM_ACCESS);
		as_wr(ADD_LCD_CMD_D, MADCTL);
		as_wr(ADD_LCD_CMD, CMD_MEM_WRITE); -- 0x2C
		as_wr(ADD_CONTROL, CTRL_GO);
		if AM_read = '0' then
				wait until AM_read = '1';
		end if;
		AM_waitrequest <= '1';
		wait for 100 ns;
		AM_waitrequest <= '0';
		DDR3_response;

		as_wr(ADD_CONTROL, ALL0_32b);

		for I in 0 to TRANS_L_int/BURSTLEN_int -2 loop
			if AM_read = '0' then
				wait until AM_read = '1';
			end if;
			DDR3_response;
		end loop;

		wait until rising_edge(clk);
		wait for 240*5*CLK_PER; -- let LCD_controller send all pixels

		----------------------------------------------------------------------------

		--as_wr(ADD_CONTROL, CTRL_GO);
		--if AM_read = '0' then
		--		wait until AM_read = '1';
		--end if;
		--AM_waitrequest <= '1';
		--wait for 100 ns;
		--AM_waitrequest <= '0';
		--DDR3_response;

		--as_wr(ADD_CONTROL, ALL0_32b);

		--for I in 0 to TRANS_L_int/BURSTLEN_int -1 loop
		--	if AM_read = '0' then
		--		wait until AM_read = '1';
		--	end if;
		--	DDR3_response;
		--end loop;

		--wait until rising_edge(clk);
		--wait for 240*5*CLK_PER; -- let LCD_controller send all pixels

		wait for 6*CLK_PER;

		finished <= true;
		wait;
	end process SIM;
end architecture simple;