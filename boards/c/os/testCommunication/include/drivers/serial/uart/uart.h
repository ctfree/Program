/*
 * Driver to use UART.
 * This module also include some usefull functions to write/read string and integer
 * to/from the UART
 *
 * A lot if this code come from the original PowWow library.
 */

#ifndef __UART_H
#define __UART_H

#include <stdbool.h>
#include <stdarg.h>

/* Size of the RX buffer (bytes) */
#define   SERIAL_SIZE_RX_BUFFER  20
/* Size of the TX buffer (bytes) */
#define   SERIAL_SIZE_TX_BUFFER  20
/* Size of the buffer used for printf like formating */
#define   SERIAL_SIZE_PRINTF_BUFFER 20
/* Size of the buffer used for int to string conversion */
#define   SERIAL_SIZE_ITOA_BUFFER 10

/*
 * Initialize UART;
 * This function must be called before any operation involving UART is done
 */
void uart_init(void);

/*
 * Write a character on UART
 */
void uart_putchar(char c);

/*
 * Write a string on UART.
 * The string must end with the 0 charactere
 */
void uart_puts(const char * string);

/*
 * Write a formated string on UART using printf like formatting.
 * The size of the generated string is returned, and must be smaller that the UART buffer size
 */
int uart_printf(const char * format, ...);

/*
 * Write an integer on UART.
 *
 * param a: integer to output
 * param b: base to use for formatting
 */
void uart_send_int(int n, int b);

/*
 * Write a float on UART
 *
 * param x: float to write
 * param p: precision
 */
void uart_send_float(float x, unsigned int p);

/*
 * Write an unsigned integer on UART.
 *
 * param a: integer to output
 * param b: base to use for formatting
 */
void uart_send_uint(unsigned int n, unsigned int b);

/*
 * Macro to write an integer on UART using base 10 for formatting
 */
#define serial_send_int10(n) serial_send_int(n, 10);

/*
 * Returns true if a character is been send by the UART, false otherwise.
 */
bool uart_is_sending(void);

/*
 * Block until the UART TX buffer is empty
 */
void uart_flush(void);

/*
 * Return true if the UART is currently receiving a character, false otherwise
 */
bool uart_is_reciving(void);

/*
 * Returns the number of bytes currenlty available to be received
 */
int uart_rx_bytes_available(void);

/*
 * Returns true if the RX buffer is full, false otherwise
 */
bool uart_rx_buffer_full(void);

/*
 * Read the next available byte in the UART RX buffer.
 * Return the 0 character ('\0') if the buffer is empty
 */
char uart_getchar(void);

/*
 * If a string has been received and is in the RX buffer, return the length of
 * this string.
 * If the buffer is full and no string has been found, returns -1.
 * 0 otherwise.
 */
int uart_string_available(void);

/* Reads a string from the serial Rx buffer, excluding \\n or \\r character.
 * If serial Rx buffer is full, it is considered as a valid string.
 *
 * param str : Pointer to an array of chars where the C string is to be stored,
 * param num : Maximum number of characters to be read (including the final null-character).
 *
 * Returns the length of the string read if successfull. 0 if no string has been found
 */
int usart_gets(char * str, int num);

/*
 * Tells if an integer has been received in the serial Rx buffer. 
 * A valid integer must be followed by at least one non-digit character.
 *
 * Returns 1 if at least 1 digit was found in the buffer, -1 if buffer is full
 * (and no digit found) otherwise 0.
 */
int uart_int_available(void);

/*
 * Parse the buffer and retreive the first integer found.
 * Notice that any character before the first integer is lost.
 * A valid integer must be followed by at least one non-digit character.
 */
int uart_read_int(void);

/*
 * Purge the RX buffer
 */
void uart_rx_purge(void);

#endif

