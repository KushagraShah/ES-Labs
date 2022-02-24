/*
 * LT24.h
 *
 *  Created on: 16 déc. 2020
 *      Author: Vassili
 */

#ifndef LT24_H_
#define LT24_H_

#include "alt_types.h"

// === CONSTANTS ===
// Register Map
#define ADD_READADDRESS 0 *4
#define ADD_LENGTH		1 *4
#define ADD_BURSTCOUNT 	2 *4
#define ADD_STATUS 		3 *4
#define ADD_CONTROL		4 *4
#define ADD_LCD_CMD		5 *4
#define ADD_LCD_DATA	6 *4

void lcd_on();
void lcd_init();
void lcd_wait();
void lcd_read(alt_u32 address, alt_u32 read_len, alt_32 burst_len);
void Delay_Ms(alt_u16);
void lcd_reset();

#endif /* LT24_H_ */
