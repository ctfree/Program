/*
 * Driver to use UART.
 * This module also include some usefull functions to write/read string and integer
 * to/from the UART
 *
 * A lot if this code come from the original PowWow library.
 */

#include <drivers/serial/uart/uart.h>
#include <stdio.h>
#include <msp430.h>
#include <math.h>

/*
 * RX buffer
 */
struct UART_RX_buffer 
{
  unsigned int begin;
  volatile unsigned int size;
  unsigned char fifo[SERIAL_SIZE_RX_BUFFER];
};

/*
 * TX buffer
 */
struct UART_TX_buffer
{
  unsigned int begin;
  volatile unsigned int size;
  unsigned char fifo[SERIAL_SIZE_TX_BUFFER];
};

/* RX and TX buffer */
static struct UART_RX_buffer rx_buffer;
static struct UART_TX_buffer tx_buffer;

static volatile bool receiving = false;
static bool sending = false;

//Enable Interrupt macros
#define SERIAL_EI_TX()    { IE1 |= UTXIE0; }
#define SERIAL_EI_RX()    { IE1 |= URXIE0; }

//Disable Interrupt macros
#define SERIAL_DI_TX()    { IE1 &= ~UTXIE0; }
#define SERIAL_DI_RX()    { IE1 &= ~URXIE0; }

// Usefull stuff
#define URXIF	( IFG1 & URXIFG0 )

/*
 * Initialize UART;
 * This function must be called before any operation involving UART is done
 */
void uart_init(void)
{
	U0CTL |= SWRST;


	ME1 |= UTXE0 + URXE0;
	U0CTL |= CHAR;
	U0TCTL |= SSEL1 + URXSE;
	U0RCTL |= URXEIE;
	U0BR1 = 2;
	U0BR0 = 9;
	U0MCTL = 0x4A;
	U0CTL &= ~SWRST;
	IFG1 &= ~URXIFG0;
    SERIAL_EI_RX();

	/* P3.4 : TX
	 * P3.5 : RX */
	P3OUT |= BIT4;
	P3DIR |= BIT4;
	P3SEL |= BIT4 + BIT5;

	//init Rx and Tx FIFOs
	rx_buffer.begin=0u;
	rx_buffer.size=0u;
	tx_buffer.begin=0u;
	tx_buffer.size=0u;
}

/*
 * Write a character on UART
 */
void uart_putchar(char c)
{
	char position;

	// FIXME: This is durty. Do better
	if (tx_buffer.size == SERIAL_SIZE_TX_BUFFER) {
		// Wait for the FIFO to have at least one free place
		while (!(tx_buffer.size < SERIAL_SIZE_TX_BUFFER));
	}
	//Disable Interrupt for MUTEX
	SERIAL_DI_TX();
	// FIXME: This is durty. Do better
	if (tx_buffer.size > SERIAL_SIZE_TX_BUFFER) {
		tx_buffer.size = 0u;
		tx_buffer.begin = 0u;
	}
	// Add the character in the Tx FIFO
	position = tx_buffer.begin + tx_buffer.size;
	// Faster than % modulo
	if (position >= SERIAL_SIZE_TX_BUFFER) {
		position -= SERIAL_SIZE_TX_BUFFER;
	}
	tx_buffer.fifo[position] = c;
	tx_buffer.size++;
	sending = true;
	// Enable interrupt
	SERIAL_EI_TX();
}

/*
 * Write a string on UART.
 * The string must end with the 0 charactere
 */
void uart_puts(const char * string)
{
	while (*string) {
		uart_putchar(*string);
		string++;
	}
}


/*
 * Write a formated string on UART using printf like formatting.
 * The size of the generated string is returned, and must be smaller that the UART buffer size
 */
int uart_printf(const char *format, ...)
{
	char buffer[SERIAL_SIZE_PRINTF_BUFFER];
	int code;
	va_list ap;
	va_start(ap, format);
	//variadic call of snprintf()
	//compute and prints the string in buffer, truncated to SERIAL_SIZE_PRINTF_BUFFER
	code = vsnprintf(buffer, SERIAL_SIZE_PRINTF_BUFFER, format, ap);
	va_end(ap);
	//send the string to serial Tx
	uart_puts(buffer);
	return code;
}

/*
 * Write an integer on UART.
 *
 * param a: integer to output
 * param b: base to use for formatting
 */
void uart_send_int(int n, int b)
{
	static char digits[] = "0123456789ABCDEF";
	char buffer[SERIAL_SIZE_ITOA_BUFFER];
	int i = 0, sign;

	if ((sign = n) < 0) {
		n = -n;
	}

	do {
		buffer[i++] = digits[n % b];
	} while ((n /= b) > 0);

	if (sign < 0) {
		buffer[i++] = '-';
	}

	while(--i >= 0) {
		uart_putchar(buffer[i]);
	}
}

/*
 * Write a float on UART
 *
 * param x: float to write
 * param p: precision
 */
void uart_send_float(float x, unsigned int p)
{
	static char digits[] = "0123456789";
	char buffer[SERIAL_SIZE_ITOA_BUFFER];
	int i = 0, j = 0, d;
	float in;
	int sign = 1;

	if (x < 0.0f) {
		sign = 0;
		x = -x;
	}

	for (i = 0; i < p; i++) {
		x = x * 10.0f;
	}

	if (x == 0.0f) {
		buffer[j++] = '0';
	} else {
		do {
			modff(x, &in);
			if (i == 0) {
				buffer[j++] = '.';
			}
			i--;
			d = (int)fmodf(in, 10.0f);
			buffer[j++] = digits[d];
			x /= 10.0f;
		} while (x >= 1.0f);

		if (i >= 0) {
			while (i > 0) {
				buffer[j++] = '0';
				i--;
			}
			buffer[j++] = '.';
			buffer[j++] = '0';
		}

		if (!sign) {
			buffer[j++] = '-';
		}
	}

	j--;
	while (j >= 0) {
		uart_putchar(buffer[j--]);
	}
}

/*
 * Write an unsigned integer on UART.
 *
 * param a: integer to output
 * param b: base to use for formatting
 */
void uart_send_uint(unsigned int n, unsigned int b)
{
	static char digits[] = "0123456789ABCDEF";
	char buffer[SERIAL_SIZE_ITOA_BUFFER];
	int i = 0;

	do {
		buffer[i++] = digits[n % b];
	} while ((n /= b) > 0);

	while(--i >= 0) {
		uart_putchar(buffer[i]);
	}
}

/*
 * Returns true if a character is been send by the UART, false otherwise.
 */
bool uart_is_sending(void)
{
	//sending set in uart_putchar(), cleared in Tx Interrupt
	//TX_BUF_READY()=0 if Tx is transmitting
	return sending || !(U0TCTL & TXEPT);
}

/*
 * Block until the UART TX buffer is empty
 */
void uart_flush(void)
{
	while(uart_is_sending());
}

/*
 * Return true if the UART is currently receiving a character, false otherwise
 */
bool uart_is_reciving(void)
{
	return receiving;
}

/*
 * Returns the number of bytes currenlty available to be received
 */
int uart_rx_bytes_available(void)
{
	return rx_buffer.size;
}

/*
 * Returns true if the RX buffer is full, false otherwise
 */
bool uart_rx_buffer_full(void)
{
	return (rx_buffer.size == SERIAL_SIZE_RX_BUFFER);
}

/*
 * Read the next available byte in the UART RX buffer.
 * Return the 0 character ('\0') if the buffer is empty
 */
char uart_getchar(void)
{
	char ret;

	if(!uart_rx_bytes_available()) {
		return 0;
	}
	
	//Disable interrupt for MUTEX
	SERIAL_DI_RX();
	
	//remove the character from the Rx fifo
	ret = rx_buffer.fifo[rx_buffer.begin];
	rx_buffer.begin++;
	
	//Faster than % modulo
	if(rx_buffer.begin == SERIAL_SIZE_RX_BUFFER) {
		rx_buffer.begin=0;
	}
	rx_buffer.size--;
	
	//EI
	SERIAL_EI_RX();

	return ret;

}

/*
 * If a string has been received and is in the RX buffer, return the length of
 * this string.
 * If the buffer is full and no string has been found, returns -1.
 * 0 otherwise.
 */
int uart_string_available(void)
{
	int i, size_counter=0, buffer_size;

	SERIAL_DI_RX();
	i = rx_buffer.begin;
	buffer_size = rx_buffer.size;
	SERIAL_EI_RX();

	//search for end of line or carriage return in the buffer
	while(size_counter < buffer_size) {
		if(rx_buffer.fifo[i] == '\n' || rx_buffer.fifo[i] == '\r') {
			return size_counter; // a string has been found
		}
		size_counter++;
		i++;
		
		//Faster than % modulo
		if(i == SERIAL_SIZE_RX_BUFFER) {
			i = 0;
		}
	}
	
	//If buffer full, and no string found return -1
	if (rx_buffer.size == SERIAL_SIZE_RX_BUFFER) {
		return -1;
	}

	return 0;
}

/* Reads a string from the serial Rx buffer, excluding \\n or \\r character.
 * If serial Rx buffer is full, it is considered as a valid string.
 *
 * param str : Pointer to an array of chars where the C string is to be stored,
 * param num : Maximum number of characters to be read (including the final null-character).
 *
 * Returns the length of the string read if successfull. 0 if no string has been found
 */
int usart_gets(char * str, int num)
{
	int i;

	//Buffer full, returns the buffer
	if (uart_rx_buffer_full()) {
		i = 0;
	
		while (uart_rx_bytes_available() && i < num-1) {
			str[i] = uart_getchar(); //Mutex handled by getchar
			i++;
		}
		str[i] = 0; //'\0'

		return i;
	}

	// No string available, returns 0
	if (!uart_string_available()) {
		str[0] = 0; //'\0'
		return 0;
	}

	//A string is present in the buffer, returns the string
	i = 0;
	str[i] = uart_getchar();
	while (str[i] != '\n' && str[i] != '\r' && ++i<num-1) {
		str[i] = uart_getchar(); //Mutex handled by getchar
	}
	str[i] = 0; //'\0'

	return i;
}

/*
 * Tells if an integer has been received in the serial Rx buffer. 
 * A valid integer must be followed by at least one non-digit character.
 *
 * Returns 1 if at least 1 digit was found in the buffer, -1 if buffer is full 
 * (and no digit found) otherwise 0.
 */
int uart_int_available(void)
{
	int i, buffer_size, size_counter=0, digit_state=0, nb_digits=0;

	SERIAL_DI_RX();
	i = rx_buffer.begin;
	buffer_size = rx_buffer.size;
	SERIAL_EI_RX();

	//search for a digit [0, 9] in the buffer
	while (size_counter < buffer_size && digit_state == 0) {
		if (rx_buffer.fifo[i] >= '0' && rx_buffer.fifo[i] <= '9'){
			digit_state=1; //a digit has been found
			nb_digits=1;
		}
		size_counter++;
		i++;
		//Faster than % modulo
		if (i==SERIAL_SIZE_RX_BUFFER) {
			i = 0;
		}
	}

	//evacuate digits and search for a non digit in the buffer
	while(size_counter < buffer_size) {
		if (rx_buffer.fifo[i] < '0' || rx_buffer.fifo[i] > '9') {
			digit_state=2;
			break;
		}
		nb_digits++;
		size_counter++;
		i++;
		if(i == SERIAL_SIZE_RX_BUFFER) {
			i = 0;
		}
	}

	//Everything went good
	if(digit_state == 2) {
		return nb_digits;
	}

	//If buffer full, and no digit found return -1
	if(rx_buffer.size == SERIAL_SIZE_RX_BUFFER && nb_digits == 0 ) {
		return -1;
	}

	//No int found, or an int was found but no non-digit character following.
	return 0;
}

/*
 * Parse the buffer and retreive the first integer found.
 * Notice that any character before the first integer is lost.
 * A valid integer must be followed by at least one non-digit character.
 */
int uart_read_int(void)
{
	long value = 0;
	char cur_char = 0, prev_char;

	//searching for the first digit
	while(uart_rx_bytes_available() && (cur_char < '0' || cur_char > '9')) {
		prev_char = cur_char;
		cur_char = uart_getchar();
	}
	//here cur_char is the 1st digit, prev_char may be a '+' or a '-'

	while(uart_rx_bytes_available() && (cur_char >= '0' && cur_char <= '9')) {
		value *= 10;
		value += cur_char - '0';
		cur_char = uart_getchar();
	}

	if(prev_char == '-') {
		value = -value;
	}

	if(value > 32767) {
		return 32767;
	}
	if(value < -32768) {
		return -32768;
	}
	
	return (int)value;
}

/*
 * Purge the RX buffer
 */
void uart_rx_purge(void)
{
	while(uart_rx_bytes_available()) {
		uart_getchar();  
	}
}



#pragma vector=USART0RX_VECTOR
__interrupt void uart0RX_interrupt(void)
{
	int position;
	char temp;

	//slau049f.pdf p268
	if (URXIF) {       //a character was received
		receiving = false;
		if (!(U0RCTL & RXERR)) {
			temp = RXBUF0;
			if (rx_buffer.size < SERIAL_SIZE_RX_BUFFER) { //buffer not full
				position = rx_buffer.begin + rx_buffer.size;
				//Faster than % modulo
				if (position >= SERIAL_SIZE_RX_BUFFER) {
					position -= SERIAL_SIZE_RX_BUFFER;
				}
				rx_buffer.fifo[position] = temp;
				rx_buffer.size++;
			}
		} else {
			RXBUF0;
		}
	} else { //a start edge was detected
		U0TCTL &= ~URXSE;
		U0TCTL |= URXSE;
		LPM3_EXIT; //enable the BRCLK
		receiving = true;
	}
}

#pragma vector=USART0TX_VECTOR
__interrupt void uart0TX_interrupt(void)
{
	//remove the character from the Tx fifo
	TXBUF0 = tx_buffer.fifo[tx_buffer.begin];
	tx_buffer.begin++;

	if (tx_buffer.begin == SERIAL_SIZE_TX_BUFFER) {
		tx_buffer.begin = 0;
	}
	tx_buffer.size--;

	//if the fifo is empty, disable interrupt
	if (tx_buffer.size == 0){
		SERIAL_DI_TX();
		sending = false;
	}
}

