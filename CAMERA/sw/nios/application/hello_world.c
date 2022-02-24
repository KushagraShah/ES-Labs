#include <stdbool.h>
#include <stdint.h>
#include <stdlib.h>
#include <stdio.h>

#include "io.h"
#include "system.h"

#include "trdb_d5m.h"

int main(void) {

	trdb_d5m_init();

	printf("End of configuration\n");

	trdb_d5m_start_acq();

	printf("Waiting for completion\n");

	trdb_d5m_wait_end();

	printf("\nFinished.\n");
    return EXIT_SUCCESS;

 }
