/*
 * I2C driver
 */

#include <msp430.h>
#include <drivers/serial/uart/uart.h>

#define START I2CTCTL |= I2CSTT
#define STOP I2CTCTL |= I2CSTP

/*
 * Initialize the I2C driver.
 * Must be called before any operation involving the I2C driver is done
 */
void i2c_init(void)
{
	// Pin mapping
	//	3.1 - SDA
	//	3.3 - SCL

	U0CTL |=SWRST;
	U0CTL = I2C | SYNC;
	P3SEL |= 0x0A; //select I2C pins
	I2CTCTL = I2CSSEL0+I2CTRX; //clock selection
	U0CTL |= I2CEN; //enable I2C module
	U0CTL |= MST; 
}

/*
 * Disable I2C and enable UART
 */
void i2c_to_uart(void)
{
	// FIRST: disable I2C following reconmmandations
	U0CTL &= ~I2C;
	U0CTL &= ~SYNC; 
	U0CTL &= ~I2CEN;
	U0CTL |=SWRST;
	
	//THEN: configure UART
	uart_init();
}

/*
 * Disable UART and enable I2C
 */
void uart_to_i2c(void)
{
	// Precautions before configuring I2C
	uart_flush();
	while (uart_is_reciving() || uart_is_sending());
	
	// configure I2C
	i2c_init();
}

