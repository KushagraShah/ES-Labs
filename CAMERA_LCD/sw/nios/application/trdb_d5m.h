/*
 * trdb_d5m.h
 *
 *  Created on: Jan 5, 2021
 *      Author: clyde
 */

#ifndef TRDB_D5M_H_
#define TRDB_D5M_H_

bool trdb_d5m_init(void);
void trdb_d5m_start_acq(uint32_t address);
void trdb_d5m_wait_end(void);
void trdb_d5m_write_image(void);

#endif /* TRDB_D5M_H_ */
