-- File 			: AS_registers.vhd
-- Entity		: AS_registers(AS)
-- Description : Avalon Slave interface. Stores internal registers and connect
--						them to other submodules.
-- Author		: Vassili Cruchet
-- Date			: December 2020
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity AS_registers is
	port (
		clk 		: in std_logic; -- main clock
		nReset	: in std_logic; -- active-low reset

		-- LCD controller signals
		LCD_cmd 		: out std_logic_vector(15 downto 0);
		LCD_cmd_d 	: out std_logic_vector(15 downto 0);
		LCD_cmd_en	: out std_logic; -- enable LCD controller to send a command
		LCD_data_en : out std_logic; -- enable LCD controller to send data
		LCD_ack 		: in std_logic; -- LCD controller has registered the command

		-- master_control signals
		-- control
		AM_ctl_go 		: out std_logic;
		AM_ctl_stop		: out std_logic;
		AM_ctl_pause 	: out std_logic;
		-- status
		AM_stat_done 	: in std_logic;
		AM_stat_busy 	: in std_logic;
		-- parameters
		AM_rd_add		: out std_logic_vector(31 downto 0);
		AM_rd_len		: out std_logic_vector(31 downto 0);
		AM_burstcount 	: out	std_logic_vector(6 downto 0);

		-- Avalon Slace (AS) interface
		address			: in std_logic_vector(2 downto 0);
		write 			: in std_logic;
		writedata		: in std_logic_vector(31 downto 0);
		read 				: in std_logic;
		readdata			: out std_logic_vector(31 downto 0);
		waitrequest 	: out std_logic
		);
end entity AS_registers;

architecture AS of AS_registers is
	type state_type is (IDLE, AS_READ, AS_WRITE, WAIT_LCD);

	-----------------------------------------------------------------------------
	-- Register map adresses
	constant ADD_READADDRESS : std_logic_vector(2 downto 0) := "000";
	constant ADD_LENGTH 		 : std_logic_vector(2 downto 0) := "001";
	constant ADD_BURSTCNT	 : std_logic_vector(2 downto 0) := "010";
	constant ADD_STATUS		 : std_logic_vector(2 downto 0) := "011";
	constant ADD_CONTROL		 : std_logic_vector(2 downto 0) := "100";
	constant ADD_LCD_CMD		 : std_logic_vector(2 downto 0) := "101";
	constant ADD_LCD_CMD_D	 : std_logic_vector(2 downto 0) := "110";

	-----------------------------------------------------------------------------
	-- Internal registers for register map
	signal iReg_readdadress_r, iReg_readdadress_n 	: std_logic_vector(31 downto 0); -- start address of buffer in DDR3
	signal iReg_length_r, iReg_length_n					: std_logic_vector(31 downto 0); -- length of the transfer (#memory words, 32bits)
	signal iReg_burstcount_r, iReg_burstcount_n		: std_logic_vector(31 downto 0); -- length of each burst transfer (#memory words, 32bits), on the 7 lower bits
	signal iReg_status_r, iReg_status_n					: std_logic_vector(31 downto 0); -- status register for the AM
	signal iReg_control_r, iReg_control_n				: std_logic_vector(31 downto 0); -- control register for the AM
	signal iReg_lcd_command_r, iReg_lcd_command_n	: std_logic_vector(31 downto 0); -- control command to LCD driver, on the 16 lower bits
	signal iReg_lcd_data_r, iReg_lcd_data_n			: std_logic_vector(31 downto 0); -- write command parameter to LCD driver, on the 16 lower bits
	-- internal signals
	signal readdata_r, readdata_n 			: std_logic_vector(31 downto 0);
	signal waitrq_r, waitrq_n 					: std_logic;
	signal LCD_cmd_en_r, LCD_cmd_en_n 		: std_logic;
	signal LCD_data_en_r, LCD_data_en_n 	: std_logic;
	signal state_r, state_n						: state_type;

begin
	-----------------------------------------------------------------------------
	-- Assign relevant register bits to output signals
	-- AS
	waitrequest <= waitrq_r;
	readdata 	<= readdata_r;
	-- LCD controller
	LCD_cmd 		<= iReg_lcd_command_r(15 downto 0);
	LCD_cmd_d	<= iReg_lcd_data_r(15 downto 0);
	LCD_cmd_en 	<= LCD_cmd_en_r;
	LCD_data_en <= LCD_data_en_r;
	-- master control
	AM_ctl_go 		<= iReg_control_r(0);
	AM_ctl_stop 	<= iReg_control_r(1);
	AM_ctl_pause 	<= iReg_control_r(2);
	AM_rd_add 		<= iReg_readdadress_r;
	AM_rd_len		<= iReg_length_r;
	AM_burstcount 	<= iReg_burstcount_r(6 downto 0);

	-----------------------------------------------------------------------------
	-- synchrone update
	process(clk, nReset) 
	begin
		if nReset = '0' then -- reset
			iReg_readdadress_r 	<= (others => '0');
			iReg_length_r			<= (others => '0');
			iReg_burstcount_r		<= (others => '0');
			iReg_status_r			<= (others => '0');
			iReg_control_r			<= (others => '0');
			iReg_lcd_command_r	<= (others => '0');
			iReg_lcd_data_r		<= (others => '0');
			readdata_r 				<= (others => '0');
			waitrq_r 				<= '1'; -- waitrequest should be asserted at reset
			LCD_cmd_en_r 			<= '0';
			LCD_data_en_r 			<= '0';
			state_r					<= IDLE;
		elsif rising_edge(clk) then
			iReg_readdadress_r	<= iReg_readdadress_n after 1 ns;
			iReg_length_r			<= iReg_length_n after 1 ns;
			iReg_burstcount_r		<= iReg_burstcount_n after 1 ns;
			iReg_status_r			<= iReg_status_n after 1 ns;
			iReg_control_r			<= iReg_control_n after 1 ns;
			iReg_lcd_command_r	<= iReg_lcd_command_n after 1 ns;
			iReg_lcd_data_r		<= iReg_lcd_data_n after 1 ns;
			readdata_r 				<= readdata_n after 1 ns;
			waitrq_r 				<= waitrq_n after 1 ns;
			LCD_cmd_en_r 			<= LCD_cmd_en_n after 1 ns;
			LCD_data_en_r 			<= LCD_data_en_n after 1 ns;
			state_r					<= state_n after 1 ns;
		end if;
	end process;

	-----------------------------------------------------------------------------
	-- next-state logic
	NSL : process(state_r, readdata_r, address, read, write, LCD_ack, AM_stat_done, AM_stat_busy)
	begin
		-- default assignment 
		iReg_readdadress_n	<= iReg_readdadress_r;
		iReg_length_n			<= iReg_length_r;
		iReg_burstcount_n		<= iReg_burstcount_r;
		iReg_control_n			<= iReg_control_r;
		iReg_lcd_command_n	<= iReg_lcd_command_r;
		iReg_lcd_data_n		<= iReg_lcd_data_r;
		readdata_n 				<= readdata_r;
		waitrq_n 				<= waitrq_r;
		LCD_cmd_en_n 			<= LCD_cmd_en_r;
		LCD_data_en_n 			<= LCD_data_en_r;
		state_n					<= state_r;

		iReg_status_n(0)		<= AM_stat_done;
		iReg_status_n(1)		<= AM_stat_busy;
		iReg_status_n(2)		<= LCD_ack;
		iReg_status_n(31 downto 3) <= iReg_status_r(31 downto 3); -- unused bits

		case state_r is
			when IDLE => 
				if read = '1' then 
					state_n 	<= AS_READ;
					waitrq_n	<= '0';
					case address is 
						when ADD_READADDRESS => readdata_n <= iReg_readdadress_r;
						when ADD_LENGTH 		=> readdata_n <= iReg_length_r;
						when ADD_BURSTCNT 	=> readdata_n <= iReg_burstcount_r;
						when ADD_STATUS 		=> readdata_n <= iReg_status_r;
						when ADD_CONTROL 		=> readdata_n <= iReg_control_r;
						when ADD_LCD_CMD 		=> readdata_n <= iReg_lcd_command_r;
						when ADD_LCD_CMD_D 	=> readdata_n <= iReg_lcd_data_r;
						when others => null;
					end case;
				elsif write = '1' then
					state_n 	<= AS_WRITE;
					-- a longer waitrq maight be needed if the LCD is busy
					if (address = ADD_LCD_CMD or address = ADD_LCD_CMD_D) and LCD_ack = '0' then
						state_n <= WAIT_LCD; -- stall the transfer
					else -- all other command can be directly sampled
						waitrq_n <= '0';
						state_n 	<= AS_WRITE;
						case address is 
							when ADD_READADDRESS => iReg_readdadress_n <= writedata;
							when ADD_LENGTH 		=> iReg_length_n <= writedata;
							when ADD_BURSTCNT 	=> iReg_burstcount_n <= writedata;
							when ADD_CONTROL 		=> iReg_control_n <= writedata;
							when ADD_LCD_CMD 		=> 
								LCD_cmd_en_n <= '1';
								iReg_lcd_command_n <= writedata;
							when ADD_LCD_CMD_D 	=> 
								LCD_data_en_n <= '1';
								iReg_lcd_data_n <= writedata;
							when others => null;
						end case;
					end if;
				else 
					state_n <= IDLE;
				end if;
			---------------------------------------------------------------------	
			when AS_READ => 
				-- data has been sampled by AM, reset values
				waitrq_n 	<= '1';
				readdata_n	<= (others => '0');
				state_n 		<= IDLE;
			
			when AS_WRITE => 
				-- writedata has been sampled by AS
				waitrq_n 	<= '1';
				state_n 		<= IDLE;
				LCD_cmd_en_n <= '0';
				LCD_data_en_n <= '0';
			when WAIT_LCD =>
				-- keep waitrq asserted to stall the transfer
				if LCD_ack = '1' then -- LCD controller not busy anymore
					waitrq_n	<= '0';
					state_n 	<= AS_WRITE;
					case address is 
						when ADD_LCD_CMD 		=> 
							LCD_cmd_en_n <= '1';
							iReg_lcd_command_n <= writedata;
						when ADD_LCD_CMD_D 	=> 
							LCD_data_en_n <= '1';
							iReg_lcd_data_n <= writedata;
						when others => null;
					end case;
				end if;
			when others => null;
		end case;
	end process NSL;

end architecture AS;