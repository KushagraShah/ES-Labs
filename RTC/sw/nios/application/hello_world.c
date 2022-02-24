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
#include <inttypes.h>
#include "system.h"
#include "io.h"

void write_digit(int digit, int number){
	  IOWR_8DIRECT(DISPALY_6MOD7SEG_1_BASE, digit+1, number);
}

int main()
{
  printf("Hello from Nios II!\n");


  // Set as output
  IOWR_8DIRECT(DISPALY_6MOD7SEG_1_BASE, 0, 0xFF);

  int i;
  for(i = 0; i < 6; i++)
	  write_digit(i,i);

  printf("dat test %d", IORD_8DIRECT(DISPALY_6MOD7SEG_1_BASE, 2));

  //int8_t temp = 0x1;
//  while(1){
//  		// Rotate
//
//  		temp <<= 1;
//  		if (temp == 0x0)    temp = 0x1;
//
//  		IOWR_8DIRECT(PARPORT_0_BASE+2, 0, temp);
//
//  		// Wait(optional)
//  		int i;
//  		for(i = 0; i < 1000; i++);
//     }

  return 0;
}

