/*
 * All kind of usefull utilitary functions.
 */

#ifndef __TOOLS_MISC_H
#define __TOOLS_MISC_H

#include <msp430.h>

/*
 * Initialialize the MSP430
 * - Set DCLOCK to 5 Mhz
 */
void msp430_init(void);

/*
* Perform frequency change on hardware master clock
*
* param select_freq : interger in 0 to 7 range. Use this parameter to select the master
* 	clock frequency (in the range defined by DCO internal resistor)
*
* param select_resist : interger in 0 to 7 range. Use this parameter to select the DCO internal
* 	resistor
*              resistor_O : 85khz to 174 khz
*              resistor_1 : xxx khz to xxx khz
*              resistor_2 : xxx khz to xxx khz
*              resistor_3 : xxx khz to xxx khz
*              resistor_4 : xxx khz to xxx khz
*              resistor_5 : xxx khz to xxx khz
*              resistor_6 : xxx khz to xxx khz
*              resistor_7 : xxx khz to xxx khz
*/
void change_master_clock(int select_freq, int select_resist);

/*
 * Watchdog management
 */
#define WDT_CLEAR 		WDTCTL = WDTPW + WDTCNTCL + WDTSSEL + WDTIS1;
#define WDT_DISABLE 	WDTCTL = WDTPW | WDTHOLD;

#endif

