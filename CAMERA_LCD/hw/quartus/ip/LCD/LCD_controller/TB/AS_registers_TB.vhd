library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity AS_registers_tb is	
end entity AS_registers_tb;

architecture simple of AS_registers_tb is
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

	-----------------------------------------------------------------------------
	-- INTERNAL SIGNALS ---------------------------------------------------------
	signal finished : boolean := false;
	signal clk 		: std_logic;
	signal nRst 	: std_logic;

	-----------------------------------------------------------------------------
	-- AS_registers signals -----------------------------------------------------
	-- AS
	signal AS_address : std_logic_vector(2 downto 0);
	signal AS_write 	: std_logic;
	signal AS_read 	: std_logic;
	signal AS_waitrequest : std_logic;
	signal AS_writedata 	: std_logic_vector(31 downto 0);
	signal AS_readdata	: std_logic_vector(31 downto 0);
	-- AM
	signal AM_ctl_go 		: std_logic;
	signal AM_ctl_stop	: std_logic;
	signal AM_ctl_pause 	: std_logic;
	signal AM_stat_done 	: std_logic;
	signal AM_stat_busy 	: std_logic;
	signal AM_rd_add		: std_logic_vector(31 downto 0);
	signal AM_rd_len		: std_logic_vector(31 downto 0);
	signal AM_burstcount : std_logic_vector(6 downto 0); 
	-- LCD
	signal LCD_cmd 		: std_logic_vector(15 downto 0);
	signal LCD_cmd_d 		: std_logic_vector(15 downto 0);
	signal LCD_cmd_en		: std_logic; -- enable LCD controller to send a command
	signal LCD_data_en 	: std_logic; -- enable LCD controller to send data
	signal LCD_ack 		: std_logic; -- LCD controller has registered the command
	-----------------------------------------------------------------------------
	
begin
	-----------------------------------------------------------------------------
	-- instantiate DUT ----------------------------------------------------------
	DUT : entity work.AS_registers
	port map (
		clk 		=> clk,
		nReset	=> nRst,
		LCD_cmd 		=> LCD_cmd,
		LCD_cmd_d 	=> LCD_cmd_d,
		LCD_cmd_en	=> LCD_cmd_en,
		LCD_data_en => LCD_data_en,
		LCD_ack 		=> LCD_ack,
		AM_ctl_go 		=> AM_ctl_go,
		AM_ctl_stop		=> AM_ctl_stop,
		AM_ctl_pause 	=> AM_ctl_pause,
		AM_stat_done 	=> AM_stat_done,
		AM_stat_busy 	=> AM_stat_busy,
		AM_rd_add		=> AM_rd_add,
		AM_rd_len		=> AM_rd_len,
		AM_burstcount 	=> AM_burstcount,
		address			=> AS_address,
		write 			=> AS_write,
		writedata		=> AS_writedata,
		read 				=> AS_read,
		readdata			=> AS_readdata,
		waitrequest 	=> AS_waitrequest);

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
		-- AVALON WRITE --
		procedure avalon_write( constant add_in 		: in std_logic_vector(2 downto 0); 
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
		end procedure avalon_write;

		--------------------------------------------------------------------------
		-- AVALON READ --
		procedure avalon_read( constant add_in : in std_logic_vector(2 downto 0)) is
			variable rd_data_out : integer;
		begin
			AS_address 		<= add_in;
			AS_read 			<= '1';

			wait until AS_waitrequest = '0';  -- hold signal assignments until waitrequest is de-asserted
			wait until rising_edge(CLK); -- data avialable at next clk rising edge
			rd_data_out := to_integer(signed(AS_readdata));

			wait until rising_edge(CLK);
			AS_address 		<= (others => '0');
			AS_read 			<= '0';

		end procedure avalon_read;

		--------------------------------------------------------------------------
		-- LCD READ ACKNOWLEDGE
		procedure lcd_rdack(constant WAIT_T : in integer) is
		begin
			LCD_ack <= '0';
			wait for WAIT_T*CLK_PER;
			LCD_ack <= '1';
		end procedure lcd_rdack;
	begin
		--------------------------------------------------------------------------
		-- default values
		nRst 		<= '1';
		AS_address 	<= (others => '0');
		AS_write 	<= '0';
		AS_read 		<= '0';
		AS_writedata 	<= (others => '0');
		LCD_ack <= '0';
		AM_stat_done <= '0';
		AM_stat_busy <= '0';

		wait for CLK_PER;
		-- reset
		async_reset;

		--------------------------------------------------------------------------
		-- simulation
		avalon_write(ADD_READADDRESS, X"0000_0001"); 
		avalon_write(ADD_LENGTH, std_logic_vector(to_unsigned(38_400, 32)));
		avalon_write(ADD_BURSTCNT, std_logic_vector(to_unsigned(16, 32)));
		avalon_write(ADD_CONTROL, X"0000_0001"); -- go!
		lcd_rdack(4); -- waitrequest for 4 clk periods
		avalon_write(ADD_LCD_CMD, X"0000_002A");
		avalon_write(ADD_LCD_CMD_D, X"0000_0001");
		avalon_write(ADD_LCD_CMD_D, X"0000_003F");

		wait for 3*CLK_PER;

		--avalon_read( ); -- read period
		--avalon_read( ); -- read duty

		wait for 3*CLK_PER;

		finished <= true;

		wait;
	end process SIM;
end architecture simple;
