/*
 * SPI drivers for PowWow
 * Most of this code comes from the first version of the Powwow firmware
 */

#ifndef __SPI_H
#define __SPI_H
                                  
#define	SPI_WAIT_TX()	while ((U1TCTL & TXEPT) == 0)  // test USART1 Tx buffer state 
#define	SPI_WAIT_RX()	while ((IFG2 & URXIFG1) == 0)  // test USART1 Rx buffer state

#define SPI_ENABLE()            P5SEL |= BIT2; \
                                P5OUT &= (~BIT0)                                  

#define SPI_DISABLE()           P5OUT |= BIT0; \
                                P5SEL &= (~BIT2)

#define SPI_TX(d)\
	do {\
		U1TXBUF = d;\
		SPI_WAIT_TX();\
	} while(0)

#define SPI_RX(d)\
	do {\
		U1TXBUF = 0;\
		SPI_WAIT_TX();\
		d = U1RXBUF;\
	} while(0)

#define SPI_WORD_RX(d)\
	do {\
		U1TXBUF = 0;\
		SPI_WAIT_TX();\
		d = U1RXBUF << 8;\
		U1TXBUF = 0;\
		SPI_WAIT_TX();\
		d |= U1RXBUF;\
	} while (0)

#define SPI_STROBE_REG(s) \
	do {\
		SPI_ENABLE();\
		SPI_TX(s);\
		SPI_DISABLE();\
	} while (0)

/*
 * Initialize SPI
 */
void spi_init(void);

#endif

