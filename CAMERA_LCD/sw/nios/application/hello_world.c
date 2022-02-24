#include <stdbool.h>
#include <stdint.h>
#include <stdlib.h>
#include <stdio.h>

#include "io.h"
#include "system.h"

#include "trdb_d5m.h"
#include "LT24.h"

#define FRAME_SPAN 153600
int main(void) {


	trdb_d5m_init();
	lcd_on();
	lcd_init();

	printf("End of configuration\n");

	trdb_d5m_start_acq(HPS_0_BRIDGES_BASE);
	trdb_d5m_wait_end();
	printf("Done\n");

	while(1){
		trdb_d5m_start_acq(HPS_0_BRIDGES_BASE+FRAME_SPAN);
		lcd_read(HPS_0_BRIDGES_BASE, FRAME_SPAN/4, 10);
		lcd_wait();
		trdb_d5m_wait_end();

		trdb_d5m_start_acq(HPS_0_BRIDGES_BASE);
		lcd_read(HPS_0_BRIDGES_BASE+FRAME_SPAN, FRAME_SPAN/4, 10);
		lcd_wait();
		trdb_d5m_wait_end();
	}


	printf("\nFinished.\n");
    return EXIT_SUCCESS;

 }
