/*
 * SPI driver for PowWow
 */

#include <drivers/serial/spi/spi.h>
#include <msp430.h>

/*
 * Initialize SPI
 */
void spi_init(void)
{

	// Port initialization
	P5DIR |= BIT0 + BIT2;                  // 0:CSn, 2:MISO, output when SPI not used
	P5SEL |= BIT1 + BIT2 + BIT3;           // Select Peripheral functionality for 1,2,3 (SPI), P5.0 digital IO
	SPI_DISABLE();                        // DISABLE CSn

	U1CTL  = CHAR + SYNC + MM + SWRST;// SW  reset, 8-bit transfer, SPI master
	U1TCTL 	= CKPH + SSEL1 + STC;    // Data on Rising Edge, SMCLK, 3-wire
	U1BR0  = 0x2; 	            // SPICLK set baud
	U1BR0  = 0xFF;	// SPICLK set baud
	U1BR1  = 0;	// Dont need baud rate control register 2 - clear it
	U1MCTL = 0;	// Dont need modulation control
	ME2   |= USPIE1;    		        // Module enable
	U1CTL &= ~SWRST;                // Remove 	RESET
}
