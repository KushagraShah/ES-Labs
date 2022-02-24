/*
 * "Hello World" example.
 *
 * This example prints 'Hello from Nios II' to the STDOUT stream. It runs on
 * the Nios II 'standard', 'full_featured', 'fast', and 'low_cost' example
 * designs. It runs with or without the MicroC/OS-II RTOS and requires a STDOUT
 * device in your system's hardware.
 * The memory footprint of this hosted application is ~69 kbytes by default
 * using the standard reference design.
 *
 * For a reduced footprint version of this template, and an explanation of how
 * to reduce the memory footprint for a given application, see the
 * "small_hello_world" template.
 *
 */

#include <stdio.h>
#include <assert.h>
#include <inttypes.h>
#include <stdlib.h>
#include "LT24.h"
#include "system.h"
#include "io.h"
#include "alt_types.h"
#include "altera_avalon_pio_regs.h"

// === CONSTANTS ===
// AM
#define AM_CTL_GO 		0x00000001
#define AM_CTL_STOP		0x00000002
#define AM_CTL_PAUSE 	0x00000004
#define ALLZERO32 		0x00000000
// HPS bridge
#define ONE_MB (1024 * 1024)
#define ONE_KB (1024)
// Display
#define DISP_L 	320
#define DISP_H	240
#define BLACK 	0x00000000
#define WHITE  	0x0000FFFF
#define RED 	0x0000F800
#define GREEN 	0x000007E0
#define BLUE 	0x0000001F
#define NFRAME  60


// === Define marcos ===
#define LT24_WR_REG(reg, val)	IOWR_32DIRECT(LCD_CONTROLLER_TOP_0_BASE, reg, val)
#define LT24_RD_REG(reg) 		IORD_32DIRECT(LCD_CONTROLLER_TOP_0_BASE, reg)
#define LCD_WR_CMD(cmd) 	IOWR_32DIRECT(LCD_CONTROLLER_TOP_0_BASE, ADD_LCD_CMD, cmd)
#define LCD_WR_DATA(data)	IOWR_32DIRECT(LCD_CONTROLLER_TOP_0_BASE, ADD_LCD_DATA, data)
#define LCD_RST_SET	 		IOWR_ALTERA_AVALON_PIO_SET_BITS(PIO_LT24_BASE, 1)
#define LCD_RST_CLR 		IOWR_ALTERA_AVALON_PIO_CLEAR_BITS(PIO_LT24_BASE, 1)
#define LCD_ON				IOWR_ALTERA_AVALON_PIO_SET_BITS(PIO_LT24_BASE, 2)
#define LCD_OFF				IOWR_ALTERA_AVALON_PIO_CLEAR_BITS(PIO_LT24_BASE, 2)

/* ====================================================================================== */
int write_DDR3(char* filename, alt_u32 start_add) {
	alt_u32 word;
	uint32_t addr = 0;
	uint32_t kilobyte_count = 0;
	uint32_t i = 0;

	printf("Writing image from %s to memory...\n", filename);

	FILE *finput = fopen(filename, "r");
	if (!finput) {
		printf("Error: could not open \"%s\" for reading\n", filename);
		return 0;
	}
	while( fscanf(finput, "%8lx", &word) != EOF ) {
		addr = start_add + i;
		if ((i % ONE_KB) == 0) {
			printf("kilobyte_count = %" PRIu32 "\naddr = 0x%lX\n", kilobyte_count, addr);
			kilobyte_count++;
		}
		IOWR_32DIRECT(addr, 0, word);
		i+= sizeof(uint32_t);
	}
	printf("last address : 0x%lX\n", addr);
	fclose(finput);
	return 1;
}

/* ====================================================================================== */

void HPS_bridge_test_write(void) {
	uint32_t megabyte_count = 0;

	for (uint32_t i = 0; i < HPS_0_BRIDGES_SPAN; i += sizeof(uint32_t)) {
		// Print progress through 256 MB memory available through address span expander
		if ((i % ONE_MB) == 0) {
			printf("megabyte_count = %" PRIu32 "\n", megabyte_count);
			megabyte_count++;
		}

		uint32_t addr = HPS_0_BRIDGES_BASE + i;

		// Write through address span expander
		uint32_t writedata = i;
		IOWR_32DIRECT(addr, 0, writedata);

		// Read through address span expander
		uint32_t readdata = IORD_32DIRECT(addr, 0);

		// Check if read data is equal to written data
		assert(writedata == readdata);
		printf("writedata = %lu\nreaddata = %lu\n", writedata, readdata);
	}
}

/* ====================================================================================== */

void send_frame(int n_pix) {
	int i = 0;

	for(i=0; i<n_pix; i++) {
		if(i<n_pix/3) {
			LCD_WR_DATA(GREEN);}
		else if(i<2*n_pix/3) {
			LCD_WR_DATA(RED);}
		else {
			LCD_WR_DATA(BLUE);}
	}
}

/* ====================================================================================== */

int main()
{
  printf("Hello from Nios II!\n");
  alt_u32 read_len 	= DISP_L*DISP_H/2;
  alt_u32 burstcnt 	= 8;
  alt_u32 read_add[NFRAME];
  alt_u32 status = 0;
  char* filename1 = "/mnt/host/TestImg/imgTest_01.ppm";
  char* filename2 = "/mnt/host/TestImg/imgTest_02.ppm";
  char* frames = "/mnt/host/TestImg/movingline_comp.ppm";

  int i = 0;

  IOWR_ALTERA_AVALON_PIO_DIRECTION(PIO_LEDS_BASE, 1);
  IOWR_ALTERA_AVALON_PIO_DATA(PIO_LEDS_BASE, 0x00);
  IOWR_ALTERA_AVALON_PIO_DIRECTION(PIO_LT24_BASE, 1);
  IOWR_ALTERA_AVALON_PIO_DATA(PIO_LT24_BASE, 0b00);

  printf("AM status  : 0x%x\n", LT24_RD_REG(ADD_STATUS));

  // start addresses
  for(i=0; i<NFRAME; i++) {
	  read_add[i] = HPS_0_BRIDGES_BASE + i*read_len/NFRAME*sizeof(uint32_t);
  }
//  write_DDR3(frames, read_add[0]);


  // AM parameters
  LT24_WR_REG(ADD_READADDRESS, read_add[0]);
  LT24_WR_REG(ADD_LENGTH, read_len);
  LT24_WR_REG(ADD_BURSTCOUNT, burstcnt);

  printf("AM Parameters : \n - Readaddress : %u\n - Length :%u\n - Burstcount : %u\n", LT24_RD_REG(ADD_READADDRESS), LT24_RD_REG(ADD_LENGTH),LT24_RD_REG(ADD_BURSTCOUNT));

  // start to read memory
  LT24_WR_REG(ADD_CONTROL, AM_CTL_GO);
  printf("AM control  : 0x%x\n", LT24_RD_REG(ADD_CONTROL));
  printf("AM status  : 0x%x\n", LT24_RD_REG(ADD_STATUS));
  LT24_WR_REG(ADD_CONTROL, ALLZERO32); // de-assert GO

  // turn on LCD
  LCD_ON;
  lcd_init();
  printf("LCD last cmd  : 0x%x\n", LT24_RD_REG(ADD_LCD_CMD));

  Delay_Ms(1000);
  printf("AM status  : 0x%x\n", LT24_RD_REG(ADD_STATUS));

  while(1) {
	  // toggle LEDS
	  IOWR_ALTERA_AVALON_PIO_DATA(PIO_LEDS_BASE, 0xFF);
	  // poll status register
	  status = LT24_RD_REG(ADD_STATUS);
	  printf("AM status  : 0x%lx\n", status);

	  for(i=0; i<NFRAME; i++) {
		  status = LT24_RD_REG(ADD_STATUS);
		  if(status == 0x05) {
			  LT24_WR_REG(ADD_READADDRESS, read_add[i]);
			  LT24_WR_REG(ADD_CONTROL, AM_CTL_GO);
			  LT24_WR_REG(ADD_CONTROL, ALLZERO32);
		  }
		  Delay_Ms(40);
	  }

//	  if(status == 0x05) { // AM done
//		  // change read frame
//		  if(LT24_RD_REG(ADD_READADDRESS) == read_add1) {
//			  LT24_WR_REG(ADD_READADDRESS, read_add2);
//
//		  }
//		  else if(LT24_RD_REG(ADD_READADDRESS) == read_add2) {
//			  LT24_WR_REG(ADD_READADDRESS, read_add1);
//		  }
//		  LT24_WR_REG(ADD_CONTROL, AM_CTL_GO);
//		  //for(i=0; i<1000; i++); // small delay
//		  LT24_WR_REG(ADD_CONTROL, ALLZERO32);
//	  }
//	  Delay_Ms(500);

	  // toggle LEDS
	  IOWR_ALTERA_AVALON_PIO_DATA(PIO_LEDS_BASE, 0x00);
	  Delay_Ms(500);
  }
  return 0;
}
