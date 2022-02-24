#include <stdbool.h>
#include <stdio.h>
#include <inttypes.h>

#include "i2c/i2c.h"
#include "io.h"
#include "system.h"

#include "trdb_d5m.h"

#define I2C_FREQ              (50000000) /* Clock frequency driving the i2c core: 50 MHz in this example (ADAPT TO YOUR DESIGN) */
#define TRDB_D5M_I2C_ADDRESS  (0xba)

#define CAMERA_FRAME_SPAN (320*240*2)

#define RED_MASK   0b1111100000000000
#define GREEN_MASK 0b0000011111100000
#define BLUE_MASK  0b0000000000011111


bool trdb_d5m_write(i2c_dev *i2c, uint8_t register_offset, uint16_t data) {
    uint8_t byte_data[2] = {(data >> 8) & 0xff, data & 0xff};

    int success = i2c_write_array(i2c, TRDB_D5M_I2C_ADDRESS, register_offset, byte_data, sizeof(byte_data));

    if (success != I2C_SUCCESS) {
        return false;
    } else {
        return true;
    }
}

bool trdb_d5m_read(i2c_dev *i2c, uint8_t register_offset, uint16_t *data) {
    uint8_t byte_data[2] = {0, 0};

    int success = i2c_read_array(i2c, TRDB_D5M_I2C_ADDRESS, register_offset, byte_data, sizeof(byte_data));

    if (success != I2C_SUCCESS) {
        return false;
    } else {
        *data = ((uint16_t) byte_data[0] << 8) + byte_data[1];
        return true;
    }
}

bool trdb_d5m_init(void){
	printf("Setting up i2c\n");
		i2c_dev i2c = i2c_inst((void *) I2C_0_BASE);
	    i2c_init(&i2c, I2C_FREQ);

	    bool success = true;

	    //Reset camera
	    //success &= trdb_d5m_write(&i2c, 16, 1);
	    //for(int i = 0; i < 1000; i++);
	    //success &= trdb_d5m_write(&i2c, 16, 0);
	    //for(int i = 0; i < 100000; i++);

	    uint16_t data = 0;

	    printf("Setting parameters...\n");

	    success &= trdb_d5m_write(&i2c, 3, (uint16_t) 1919);
	    data = 0;
	    success &= trdb_d5m_read(&i2c, 3, &data);
	    printf("Should be 1919: %u\n", data);

	    success &= trdb_d5m_write(&i2c, 4, (uint16_t)2559);

	    success &= trdb_d5m_write(&i2c, 34, 0x0033);
		success &= trdb_d5m_write(&i2c, 35, 0x0033);

		success &= trdb_d5m_write(&i2c, 160, (0<<3) + 0);
		success &= trdb_d5m_write(&i2c, 161, 4095 );
		success &= trdb_d5m_write(&i2c, 162, 4095 );
		success &= trdb_d5m_write(&i2c, 163, 4095 );

		// Set snapshot
		success &= trdb_d5m_write(&i2c, 30, 1 << 8);

		success &= trdb_d5m_write(&i2c, 11, 1);
		printf("Restarting camera\n");

		return success;
}

void trdb_d5m_start_acq(uint32_t address){
	IOWR_32DIRECT(CAMERA_MODULE_0_BASE, 4, address);
	IOWR_32DIRECT(CAMERA_MODULE_0_BASE, 0, 1);
}

void trdb_d5m_wait_end(void){
	while(IORD_32DIRECT(CAMERA_MODULE_0_BASE, 0) != 0){
			//printf("Waiting...\n");
	}
}

void trdb_d5m_write_image(void){
	// Write result
		printf("Writing result\n");
		char* filename = "/mnt/host/image.ppm";
		FILE *foutput = fopen(filename, "w");
		if (!foutput) {
			printf("Error: could not open \"%s\" for writing\n", filename);
			return;
		}

		// Header
		fprintf(foutput, "P3\n320 240 \n32\n");

		uint32_t addr = HPS_0_BRIDGES_BASE;
		for (uint32_t i = 0; i <= CAMERA_FRAME_SPAN; i += sizeof(uint32_t)) {
			addr = HPS_0_BRIDGES_BASE + i;
			// Read through address span expander
			uint32_t readdata = IORD_32DIRECT(addr, 0);
			uint16_t low_RGB = (readdata & 0x0000ffffUL);
			uint16_t high_RGB = (readdata & 0xffff0000UL) >> 16;

			fprintf(foutput, "%" PRIu8 " %" PRIu8 " %" PRIu8" " ,
					                      (uint8_t)((low_RGB & RED_MASK)   >> 11),
										  (uint8_t)((low_RGB & GREEN_MASK) >> 6 ),
										  (uint8_t)((low_RGB & BLUE_MASK)  >> 0 ));
			fprintf(foutput, "%" PRIu8 " %" PRIu8 " %" PRIu8"\n" ,
										  (uint8_t)((high_RGB & RED_MASK)   >> 11),
										  (uint8_t)((high_RGB & GREEN_MASK) >> 6 ),
										  (uint8_t)((high_RGB & BLUE_MASK)  >> 0 ));
			//printf("Read address: %" PRIu32 "\n", addr);

	    }
		printf("Done\n");
}
