/*
 * All kind of usefull utilitary functions.
 */

#include <msp430.h>

/*
 * Initialialize the MSP430
 * - Set DCLOCK to 5 Mhz
 */
void msp430_init(void)
{
	// Dclock to 5 Mhz
	// ACLK divider to 8
	DCOCTL = DCO2 + DCO1 + DCO0;
	BCSCTL1 |= RSEL0 | RSEL1 | RSEL2 | DIVA_3;
	BCSCTL2 |= DIVS_0;
}

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
void change_master_clock(int select_freq, int select_resist)
{
  DCOCTL = (DCOCTL & 0x1F) | ((select_freq & 0x7) << 5);  // Change only bit 5,6,7 of DCOCTL register
  BCSCTL1 = (BCSCTL1 & 0xF8) | (select_resist & 0x7);  // Change only bit 0,1,2 of BCSCTL1 register
}

