/*
 * RCUP V4 PowWow driver.
 * Application interface
 */

#ifndef __RCUP_V4_H
#define __RCUP_V4_H

#define RCUP_ERROR	-1
#define RCUP_SUCCESS 0

/*
 * Initialize RCUP.
 * Must be called before any operations involving RCUP is done
 */
void rcup_init(void);

/*
 * Read the current VStore
 *
 * Returns RCUP_ERROR or v_store depending on how it went.
 *
 * NOTE: Alimentation voltage should be at least 2.1V for the INA chip
 * to work.
 */
int rcup_read_voltages(void);

#endif

