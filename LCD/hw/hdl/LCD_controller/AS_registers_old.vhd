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
	-----------------------------------------------------------------------------
	-- Internal registers for register map
	signal iReg_readdadress 	: std_logic_vector(31 downto 0); -- start address of buffer in DDR3
	signal iReg_length			: std_logic_vector(31 downto 0); -- length of the transfer (#memory words, 32bits)
	signal iReg_burstcount		: std_logic_vector(31 downto 0); -- length of each burst transfer (#memory words, 32bits), on the 7 lower bits
	signal iReg_status			: std_logic_vector(31 downto 0); -- status register for the AM
	signal iReg_control			: std_logic_vector(31 downto 0); -- control register for the AM
	signal iReg_lcd_command		: std_logic_vector(31 downto 0); -- control command to LCD driver, on the 16 lower bits
	signal iReg_lcd_data			: std_logic_vector(31 downto 0); -- write command parameter to LCD driver, on the 16 lower bits
	signal waitrq_reg 			: std_logic;

begin
	-----------------------------------------------------------------------------
	-- Assign relevant register bits to output signals and vice versa
	-- AS
	waitrequest <= waitrq_reg;
	-- LCD controller
	LCD_cmd 		<= iReg_lcd_command(15 downto 0);
	LCD_cmd_d	<= iReg_lcd_data(15 downto 0);
	-- master control
	AM_ctl_go 		<= iReg_control(0);
	AM_ctl_stop 	<= iReg_control(1);
	AM_ctl_pause 	<= iReg_control(2);
	iReg_status(0) <= AM_stat_done;
	iReg_status(1) <= AM_stat_busy;
	AM_rd_add 		<= iReg_readdadress;
	AM_rd_len		<= iReg_length;
	AM_burstcount 	<= iReg_burstcount(6 downto 0);

	-----------------------------------------------------------------------------
	-- Avalon slave write to regisers.
	AS_WRITE : process(clk, nReset, write)
	begin
		if nReset = '0' then -- reset
			iReg_readdadress 	<= (others => '0');
			iReg_length			<= (others => '0');
			iReg_burstcount	<= (others => '0');
			iReg_status(31 downto 2) <= (others => '0'); -- set to '0' all unused bits
			iReg_control		<= (others => '0');
			iReg_lcd_command	<= (others => '0');
			iReg_lcd_data		<= (others => '0');
			waitrq_reg 			<= '1'; -- waitrequest should be asserted at reset
			LCD_cmd_en 			<= '0';
			LCD_data_en 		<= '0';
		elsif rising_edge(write) then
			waitrq_reg <= '1';
		elsif rising_edge(clk) then
			LCD_cmd_en 		<= '0';
			LCD_data_en 	<= '0';
			if write = '1' then
				waitrq_reg <= '0';
				case address is 
					when "000" => iReg_readdadress	<= writedata;
					when "001" => iReg_length 			<= writedata;
					when "010" => iReg_burstcount 	<= writedata;
					when "100" => iReg_control 		<= writedata;
					when "101" => 
						if LCD_ack = '1' then
							iReg_lcd_command 	<= writedata;
							LCD_cmd_en 			<= '1';
						else -- LCD not ready to recieve cmd
							waitrq_reg <= '1';
						end if;
					when "110" => 
						if LCD_ack = '1' then
							iReg_lcd_data 	<= writedata;
							LCD_data_en 	<= '1';
						else -- LCD not ready to recieve data
							waitrq_reg <= '1';
						end if;
					when others => null;
				end case;
			end if;
		end if;
	end process;

	-- Avalon slave read from regisers.
	AS_READ : process(clk)
	begin
		if rising_edge(clk) then
			readdata 		<= (others => '0'); -- default
			if read = '1' then
				case address is 
					when "000" => readdata <= iReg_readdadress;
					when "001" => readdata <= iReg_length;
					when "010" => readdata <= iReg_burstcount;
					when "011" => readdata <= iReg_status;
					when "100" => readdata <= iReg_control;
					when "101" => readdata <= iReg_lcd_command;
					when "110" => readdata <= iReg_lcd_data;
					when others => null;
				end case;
			end if;
		end if;
	end process;
end architecture AS;