/*
 * LT24.c
 *
 *  Created on: 01/2021
 *      Author: Vassili Cruchet
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

	LCD_WR_CMD(0x0029); //display on

	LCD_WR_CMD(0x0036); // Memory Access Control
		 LCD_WR_DATA(0x0028); // Row/Column Exchange

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
		 LCD_WR_DATA(0x0020); // expand 16 bits data to 18bits frame : “1” is inputted to LSB
		 LCD_WR_DATA(0x0000); // normal data transfert mode; MSB 1st

	Delay_Ms(80);
	LCD_WR_CMD(0x002c); // 0x2C, ready to get data
}

void lcd_wait() {
	alt_u32 status = LT24_RD_REG(ADD_STATUS);

    while(status & AM_STAT_BUSY) {
    	status =  LT24_RD_REG(ADD_STATUS);
    }
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
