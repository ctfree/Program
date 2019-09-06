/*
 * Very basic I2C driver for PowWow
 * Application interface
 */

#ifndef __I2C_DRIVER_H
#define __I2C_DRIVER_H

/*
 * Initialize the I2C driver.
 * Must be called before any operation involving the I2C driver is done
 */
void i2c_init(void);

/*
 * Disable I2C and enable UART
 */
void i2c_to_uart(void);

/*
 * Disable UART and enable I2C
 */
void uart_to_i2c(void);

#endif

