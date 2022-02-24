/*
 * LT24.c
 *
 *  Created on: 16 déc. 2020
 *      Author: Vassili
 */

#include <stdio.h>
#include "LT24.h"
#include "system.h"
#include "io.h"
#include "alt_types.h"
#include "altera_avalon_pio_regs.h"


// === Define marcos ===
#define LT24_WR_REG(reg, val)	IOWR_32DIRECT(LCD_CONTROLLER_TOP_0_BASE, reg, val)
#define LT24_RD_REG(reg) 		IORD_32DIRECT(LCD_CONTROLLER_TOP_0_BASE, reg)
#define LCD_WR_CMD(cmd) 	IOWR_32DIRECT(LCD_CONTROLLER_TOP_0_BASE, ADD_LCD_CMD, cmd)
#define LCD_WR_DATA(data)	IOWR_32DIRECT(LCD_CONTROLLER_TOP_0_BASE, ADD_LCD_DATA, data)
#define LCD_RST_SET	 		IOWR_ALTERA_AVALON_PIO_SET_BITS(PIO_LT24_BASE, 1)
#define LCD_RST_CLR 		IOWR_ALTERA_AVALON_PIO_CLEAR_BITS(PIO_LT24_BASE, 1)
#define LCD_ON				IOWR_ALTERA_AVALON_PIO_SET_BITS(PIO_LT24_BASE, 2)
#define LCD_OFF				IOWR_ALTERA_AVALON_PIO_CLEAR_BITS(PIO_LT24_BASE, 2)

// AM
#define AM_CTL_GO 		0x00000001
#define AM_CTL_STOP		0x00000002
#define AM_CTL_PAUSE 	0x00000004
#define AM_STAT_BUSY 	0x00000002
#define ALLZERO32 		0x00000000

void Delay_Ms(alt_u16 count_ms)
{
    while(count_ms--)
    {
        usleep(1000);
    }
}

void lcd_reset() {
	LCD_RST_SET;
	Delay_Ms(1);
	LCD_RST_CLR;
	Delay_Ms(15); // Delay 10ms // This delay time is necessary
	LCD_RST_SET;
	Delay_Ms(120); // Delay 120 ms
//	LCD_RST_CLR;
	// Clr_LCD_CS;
}

void lcd_on() {
	LCD_ON;
}

void lcd_init() {
	lcd_reset();

	LCD_WR_CMD(0x0011); //Exit Sleep
	Delay_Ms(100);
	printf("AM status  : 0x%x\n", LT24_RD_REG(ADD_STATUS));
//	LCD_WR_CMD(0x00CF); // Power Control B
//	printf("cmd  : 0x%x\nAM status  : 0x%x\n", LT24_RD_REG(ADD_LCD_CMD), LT24_RD_REG(ADD_STATUS));
//		 LCD_WR_DATA(0x0000); // Always 0x00
//		 LCD_WR_DATA(0x0081); //
//		 LCD_WR_DATA(0X00c0);
//		 printf("data  : 0x%x\nAM status  : 0x%x\n", LT24_RD_REG(ADD_LCD_DATA), LT24_RD_REG(ADD_STATUS));

	LCD_WR_CMD(0x0029); //display on


//	LCD_WR_CMD(0x00ED); // Power on sequence control
//		 LCD_WR_DATA(0x0064); // Soft Start Keep 1 frame
//		 LCD_WR_DATA(0x0003); //
//		 LCD_WR_DATA(0X0012);
//		 LCD_WR_DATA(0X0081);
//
//	LCD_WR_CMD(0x00E8); // Driver timing control A
//		 LCD_WR_DATA(0x0085);
//		 LCD_WR_DATA(0x0001);
//		 LCD_WR_DATA(0x00798);
//
//	LCD_WR_CMD(0x00CB); // Power control A
//		 LCD_WR_DATA(0x0039);
//		 LCD_WR_DATA(0x002C);
//		 LCD_WR_DATA(0x0000);
//		 LCD_WR_DATA(0x0034);
//		 LCD_WR_DATA(0x0002);
//
//	LCD_WR_CMD(0x00F7); // Pump ratio control
//	 	 LCD_WR_DATA(0x0020);
//
//	LCD_WR_CMD(0x00EA); // Driver timing control B
//	 	 LCD_WR_DATA(0x0000);
//	 	 LCD_WR_DATA(0x0000);
//
//	LCD_WR_CMD(0x00B1); // Frame Control (In Normal Mode)
//	 	 LCD_WR_DATA(0x0000); // defaults
//	 	 LCD_WR_DATA(0x001b);
//
//	LCD_WR_CMD(0x00B6); // Display Function Control
//	 	 LCD_WR_DATA(0x000A);
//	 	 LCD_WR_DATA(0x00A2);
//
//	LCD_WR_CMD(0x00C0); //Power control 1
//	 	 LCD_WR_DATA(0x0005); //VRH[5:0]
//
//	LCD_WR_CMD(0x00C1); //Power control 2
//		 LCD_WR_DATA(0x0011); //SAP[2:0];BT[3:0]
//
//	LCD_WR_CMD(0x00C5); //VCM control 1
//	 	 LCD_WR_DATA(0x0045); //3F
//	 	 LCD_WR_DATA(0x0045); //3C
//
//	LCD_WR_CMD(0x00C7); //VCM control 2
//	 	 LCD_WR_DATA(0X00a2);

	LCD_WR_CMD(0x0036); // Memory Access Control
		 LCD_WR_DATA(0x0020); // Row/Column Exchange


//	LCD_WR_CMD(0x00F2); // Enable 3G
//		 LCD_WR_DATA(0x0000); // 3Gamma Function Disable
//
//	LCD_WR_CMD(0x0026); // Gamma Set
//		 LCD_WR_DATA(0x0001); // Gamma curve selected
//	LCD_WR_CMD(0x00E0); // Positive Gamma Correction, Set Gamma
//		 LCD_WR_DATA(0x000F);
//		 LCD_WR_DATA(0x0026);
//		 LCD_WR_DATA(0x0024);
//		 LCD_WR_DATA(0x000b);
//		 LCD_WR_DATA(0x000E);
//		 LCD_WR_DATA(0x0008);
//		 LCD_WR_DATA(0x004b);
//		 LCD_WR_DATA(0X00a8);
//		 LCD_WR_DATA(0x003b);
//		 LCD_WR_DATA(0x000a);
//		 LCD_WR_DATA(0x0014);
//		 LCD_WR_DATA(0x0006);
//		 LCD_WR_DATA(0x0010);
//		 LCD_WR_DATA(0x0009);
//		 LCD_WR_DATA(0x0000);
//	LCD_WR_CMD(0X00E1); //Negative Gamma Correction, Set Gamma
//		 LCD_WR_DATA(0x0000);
//		 LCD_WR_DATA(0x001c);
//		 LCD_WR_DATA(0x0020);
//		 LCD_WR_DATA(0x0004);
//		 LCD_WR_DATA(0x0010);
//		 LCD_WR_DATA(0x0008);
//		 LCD_WR_DATA(0x0034);
//		 LCD_WR_DATA(0x0047);
//		 LCD_WR_DATA(0x0044);
//		 LCD_WR_DATA(0x0005);
//		 LCD_WR_DATA(0x000b);
//		 LCD_WR_DATA(0x0009);
//		 LCD_WR_DATA(0x002f);
//		 LCD_WR_DATA(0x0036);
//		 LCD_WR_DATA(0x000f);

	LCD_WR_CMD(0x002A); // Column Address Set
		 LCD_WR_DATA(0x0000);
		 LCD_WR_DATA(0x0000);
		 LCD_WR_DATA(0x0001);
		 LCD_WR_DATA(0x003F); //if MADCTL's B5 = 0, If B5=1, use LCD_WR_DATA(0x0013F);

	LCD_WR_CMD(0x002B); // Page Address Set
		 LCD_WR_DATA(0x0000);
		 LCD_WR_DATA(0x0000);
		 LCD_WR_DATA(0x0000);
		 LCD_WR_DATA(0x00EF); // or 0x00EF is MADCTL's B5=1

	LCD_WR_CMD(0x003A); // COLMOD: Pixel Format Set
	 	 LCD_WR_DATA(0x0055);

	LCD_WR_CMD(0x00f6); // Interface Control
		 LCD_WR_DATA(0x0001); // When the transfer number of data exceeds ( C-SC+1)*(EP-SP+1), the column and page number will be reset, and the exceeding data will be written into the following column and page.
		 LCD_WR_DATA(0x0030); // expand 16 bits data to 18bits frame : “1” is inputted to LSB
		 LCD_WR_DATA(0x0000); // normal data transfert mode; MSB 1st

	Delay_Ms(80);
	LCD_WR_CMD(0x002c); // 0x2C, ready to get data
}

void lcd_read(alt_u32 address, alt_u32 read_len, alt_32 burst_len) {
	  // AM parameters
	  LT24_WR_REG(ADD_READADDRESS, address);
	  LT24_WR_REG(ADD_LENGTH, read_len);
	  LT24_WR_REG(ADD_BURSTCOUNT, burst_len);

	  // start to read memory
	  LT24_WR_REG(ADD_CONTROL, AM_CTL_GO);
	  LT24_WR_REG(ADD_CONTROL, ALLZERO32); // de-assert GO
}

void lcd_wait() {
	alt_u32 status = LT24_RD_REG(ADD_STATUS);
	while(status & AM_STAT_BUSY) {
		status =  LT24_RD_REG(ADD_STATUS);
	}
}
