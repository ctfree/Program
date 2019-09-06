/*
 * Texas Instrument CC2520 radio chip driver
 */

#if defined CC2520

#include <msp430.h>
#include <drivers/serial/spi/spi.h>
#include <drivers/radio/cc12x.h>
#include <tools/timer/timer.h>
#include <stdbool.h>


#define RADIO_SUCCESS	0
#define RADIO_CCA_BUSY	1
#define RADIO_TIMEOUT	2
#define RADIO_ERROR_UNKNOWN	3
#define RADIO_CRC_ERROR	4
#define RADIO_WRONG_LENGTH	5
#define RADIO_NOT_IMPLEMENTED	6 // Not implemented feature

/*
 * Registers
 */
#define CC2520_EXCFLAG0        0x10
#define CC2520_GPIOCTRL4        0x24
#define CC2520_TXPOWER          0x30
#define CC2520_RSSI             0x38
#define CC2520_TXFIFO           0x100
#define CC2520_RXFIFO           0x180
#define CC2520_FREQCTRL         0x002E

/*
 * Instructions
 */
#define CC2520_SNOP             0x00
#define CC2520_SSAMPLECCA       0x04
#define CC2520_MEMRD            0x10
#define CC2520_MEMWR            0x20
#define CC2520_RXBUF            0x30
#define CC2520_TXBUF            0x3A
#define CC2520_SXOSCON          0x40
#define CC2520_SXOSCOFF         0x46
#define CC2520_REGRD            0x80
#define CC2520_REGWR            0xC0

#define CC2520_SRXON            0x42
#define CC2520_STXON            0x43
#define CC2520_STXONCCA         0x44
#define CC2520_SRFOFF           0x45
#define CC2520_SXOSCOFF         0x46
#define CC2520_SFLUSHRX         0x47
#define CC2520_SFLUSHTX         0x48

/*
 * Status bytes
 */
#define CC2520_XOSC16M_STABLE	7
#define CC2520_RSSI_VALID	6
#define CC2520_TX_ACTIVE	1
#define CC2520_RX_OVERFLOW	6

/*
 * RSSI
 */
#define RSSI_OFFSET -53
#define RSSI_2_ED(rssi)   ((rssi) < RSSI_OFFSET ? 0 : ((rssi) - (RSSI_OFFSET)))
#define ED_2_LQI(ed) (((ed) > 63 ? 255 : ((ed) << 2)))

/*
 * Length byte
 */
#define BASIC_RF_LENGTH_MASK            0x7F

/*
 * Radio IO ports on PowWow
 */

#define BM(n) (1 << (n))
#define CCRESET      2  // P6.2 - Output: CCRESET to CC2520
#define CCVEN        4  // P2.4 - Output: CCVEN to CC2520
#define FIFO         ((P4IN&BIT2)==BIT2)
#define FIFOP        ((P4IN&BIT3)==BIT3)
#define CCA          ((P2IN&BIT6)==BIT6)
#define SET_RESET_INACTIVE()    ( P6OUT |=  BM(CCRESET) )
#define SET_RESET_ACTIVE()      ( P6OUT &= ~BM(CCRESET) )
#define SET_VREG_ACTIVE()       ( P2OUT |=  BM(CCVEN) )
#define SET_VREG_INACTIVE()     ( P2OUT &= ~BM(CCVEN) )

/*
 * SPI access
 */
#define SPI_ADDR_TX(a)\
	do {\
		U1TXBUF = CC2520_MEMWR | ((a>>8)&0xF);\
		SPI_WAIT_TX();\
		U1TXBUF = a&0xFF;\
		SPI_WAIT_TX();\
	} while (0)

#define SPI_ADDR_RX(a)\
	do {\
		U1TXBUF = CC2520_MEMRD | ((a>>8)&0xF);\
		SPI_WAIT_TX();\
		U1TXBUF = a&0xFF;\
		SPI_WAIT_TX();\
	} while (0)

#define SPI_SET_REG_VALUE(a,v)\
	do {\
		SPI_ENABLE();\
		SPI_ADDR_TX(a);\
		SPI_TX((unsigned char) (v));\
		SPI_DISABLE();\
	} while (0)

#define SPI_GET_REG_VALUE(a,v)\
	do {\
		SPI_ENABLE();\
		SPI_ADDR_RX(a);\
		v= (unsigned char)U1RXBUF;\
		SPI_RX(v);\
		_NOP();\
		SPI_DISABLE();\
	} while (0)

#define SPI_UPDATE_STATUS_REG(s)\
	do {\
		SPI_ENABLE();\
		U1TXBUF = CC2520_SNOP;\
		SPI_WAIT_TX();\
		s = U1RXBUF;\
		SPI_DISABLE();\
	} while (0)
 
#define SPI_FIFO_WRITE(p,c)\
	do {\
	    SPI_ENABLE();\
	    SPI_TX(CC2520_TXBUF);\
	    for (unsigned char i = 0; i < (c); i++) {\
		SPI_TX(((unsigned char*)(p))[i]);\
	    }\
	    SPI_DISABLE();\
    } while (0)

#define SPI_READ_FIFO_BYTE(b)\
	do {\
		SPI_ENABLE();\
		SPI_TX(CC2520_RXBUF);\
		SPI_RX(b);\
		_NOP();\
		SPI_DISABLE();\
	} while (0)

#define SPI_QUICK_READ_FIFO(p,c)\
	do {\
		SPI_ENABLE();\
		SPI_TX(CC2520_RXBUF);\
		for (unsigned char spiCnt = 0; spiCnt < (c); spiCnt++) {\
			SPI_RX(((unsigned char*)(p))[spiCnt]);\
		}\
		_NOP();\
		SPI_DISABLE();\
	} while (0)

/*
 * Waits for the crystal oscillator to become stable. The flag ispolled via the SPI status byte.
 *
 * Note that this function will lock up if the SXOSCON commandstrobe has not been given before the
 * function call. Also note that global interrupts will always beenabled when this function
 * returns.
 */
static bool wait_for_crystal_osc_to_be_stable(void) 
{
   int spi_status_byte;
   int timeout = 1000;

	// Poll the SPI status byte until the crystal oscillator is stable
	do  {
		SPI_UPDATE_STATUS_REG(spi_status_byte);
        timeout--;             
	}  while (!(spi_status_byte & (BM(CC2520_XOSC16M_STABLE))) && timeout);
        
	if (!timeout) {
	  return false;
	}
	
	return true;

}

/*
 * Init the radio
 *
 * Returns true if the initialization was a success. Returns false otherwise.
 * Initialization can fail if the oscillator failed to stabilize.
 *
 * Timer tools and SPI must be initialized before calling this function.
 */
bool radio_init(void)
{
	// Ports setup
	// CCVEN    CCVEN    P2.4  out (MSP -> CC2520)
	// CCRST    CCRST    P6.2  out
	// GPIO0    clk      P2.0  in  (CC2520 -> MSP)
	// GPIO1    CCFIFO   P4.2  in 
	// GPIO2    CCFIFOP  P4.3  in
	// GPIO3    CCCA     P2.6  in
	// GPIO4    CCSFD    P2.3  in /!\ CC2520 output shorted to GND on MSP2ZIGv4
	// GPIO5    UNUSED   P6.0  out
	P2DIR |= BIT4 + BIT3;
  	P6DIR |= BIT2;

	SET_RESET_ACTIVE();
	SET_VREG_ACTIVE();
	set_accurate_timer(3273u);	// ~10ms
	while (!has_accurate_timer_expired());
	SET_RESET_INACTIVE();

	if (wait_for_crystal_osc_to_be_stable()) {


		//Update needed fore some registers
		//See cc2520.pdf p103
		SPI_SET_REG_VALUE(CC2520_TXPOWER, 0x32); //TXPOWER
		SPI_SET_REG_VALUE(0x36, 0xF8); //CCACTRL0
		SPI_SET_REG_VALUE(0x46, 0x85); //MDMCTRL0 p123
		SPI_SET_REG_VALUE(0x47, 0x14); //MDMCTRL1 p123
		SPI_SET_REG_VALUE(0x4A, 0x3F); //RXCTRL
		SPI_SET_REG_VALUE(0x4C, 0x5A); //FSCTRL
		SPI_SET_REG_VALUE(0x4F, 0x2B); //FSCAL1
		SPI_SET_REG_VALUE(0x53, 0x11); //AGCCTRL1
		SPI_SET_REG_VALUE(0x56, 0x10); //ADCTEST0
		SPI_SET_REG_VALUE(0x57, 0x0E); //ADCTEST1
		SPI_SET_REG_VALUE(0x58, 0x03); //ADCTEST2

		SPI_SET_REG_VALUE(0x00, 0x0); //FRMFILT0 : filter disable
		SPI_SET_REG_VALUE(0x01, 0xF8); //FRMFILT1 : no frame reject
		//FRMCTRL0 : autocrc, no autoack
		SPI_SET_REG_VALUE(0x2E, 11); //FREQCTRL : canal 11
		//CCACTRL1 : CCA mode=1
		SPI_SET_REG_VALUE(0x44, 0); //EXTCLOCK : clock off
		SPI_SET_REG_VALUE(CC2520_GPIOCTRL4, 0x80); //GPIO4 is input (avoid short to GND on MSP2ZIGv4)

		return true;
	}

	return false;
}

/*
 * Get level of input radio signal (RSSI)
 */
static int get_rssi(void)
{
	int f;
	int ff;
	//signed char n;

	SPI_GET_REG_VALUE(CC2520_RSSI, f);	// Get register value

	//n = f & 0xff;	// Translate register value to char
	ff=f;

	return  ff;
}

/*
 * Wake up the radio from sleep mode
 */
void radio_wakeup(void)
{
	radio_init();
}

/*
 * Put the radio in sleep mode
 */
void radio_powerdown(void)
{
	SPI_STROBE_REG(CC2520_SXOSCOFF);  
	SET_VREG_INACTIVE(); 
	SET_RESET_ACTIVE(); 
}

/*
 * Change the TX power. The possible values are:
 * 	1 : -18 dBm
 * 	2 : -7  dBm
 * 	3 : -4  dBm
 * 	4 : -2  dBm
 * 	5 :  0  dBm
 * 	6 :  1  dBm
 * 	7 :  2  dBm
 *  8 :  3  dBm
 *  9 :  5  dBm
 */
void radio_change_tx_power(int new_tx_power)
{
	int level;
	switch (new_tx_power) {
	case 1 :
		level = 0x03; //-18dBm
	break;

	case 2 :
		level = 0x2C; //-7dBm
	break;

	case 3 :
		level = 0x88; //-4dBm
	break;

	case 4 :
		level = 0x81; //-2dBm
	break;

	case 5 :
		level = 0x32; //0dBm
	break;

	case 6 :
		level = 0x13; //1dBm
	break;

	case 7 :
		level = 0xAB; //2dBm
	break;

	case 8 :
		level = 0xF2; //3dBm
	break;

	case 9 :
		level = 0xF7; //5dBm
	break;

	default :
		level = 0x32; //default : 0dBm
	break;
	}

	SPI_SET_REG_VALUE(CC2520_TXPOWER,level);
}

/*
 * change the channel. must in the range [11,26].
 */
void radio_change_channel(int new_channel)
{
	unsigned int new_register_value;

	if (new_channel < 11 || new_channel > 26) {
		new_channel = 11;
	}

	new_register_value = 11 + (new_channel - 11)*5; // compute register channel value
	SPI_SET_REG_VALUE(CC2520_FREQCTRL, new_register_value);
}

/*
 * Send data.
 * 
 * param buffer: data to send
 * param n_bytes: number of bytes from buffer to send
 * param cca: If true, perform a CCA before sending the frame. Else, send the
 * 	frame directly without CCA.
 *
 * Returns RADIO_SUCCES, RADIO_CCA_BUSY or RADIO_ERROR_UNKNOWN depending on how it went.
 */
int radio_send(const void *buffer, int n_bytes, bool do_cca)
{
	unsigned int spi_status_byte;

	SPI_FIFO_WRITE((unsigned char*)&n_bytes,(unsigned char)1);		// Transfert length
	SPI_FIFO_WRITE((unsigned char*)buffer,(unsigned char)n_bytes);	// Transfert data}

	if (do_cca) {
  		SPI_STROBE_REG(CC2520_SRXON);	// Switch to RX mode to listen channel
		  do  {
			SPI_UPDATE_STATUS_REG(spi_status_byte);	// Wait for RSSI to be valid
		  }  while (!(spi_status_byte & (BM(CC2520_RSSI_VALID))));
		  
		  SPI_STROBE_REG(CC2520_STXONCCA);	// Send FIFO data when channel is free (CSMA-CA)
	} else {
		SPI_STROBE_REG(CC2520_STXON);	// Starting transmission
	}

  SPI_UPDATE_STATUS_REG(spi_status_byte);
  if((spi_status_byte & (BM(CC2520_TX_ACTIVE)))) {
	  do {
		  SPI_UPDATE_STATUS_REG(spi_status_byte);
	  }
	  while (spi_status_byte & BM(CC2520_TX_ACTIVE));
	  
	  SPI_STROBE_REG(CC2520_SRFOFF);				// Return to Idle mode

	  return RADIO_SUCCESS;
  	} else {
		SPI_STROBE_REG(CC2520_SFLUSHTX);	// Flush TXFIFO
		SPI_STROBE_REG(CC2520_SRFOFF);		// Switch to Idle mode

		if (do_cca) {
			return RADIO_CCA_BUSY;
		} else {
			return RADIO_ERROR_UNKNOWN;
		}
	}
}

/*
 * Receive data.
 *
 * param buffer: buffer where to store received data.
 * param n_bytes: maximum number of bytes to receive, including 2 CRC bytes at the end.
 * param timeout: maximum time to wait (30us is the timer unit). Cannot exceed 1.99s
 * param strength: will be set to the strength of the radio signal.
 *
 * Returns RADIO_SUCESS, RADIO_TIMEOUT, RADIO_CRC_ERROR or RADIO_WRONG_LENGTH
 * 	depending on how it went.
 */
int radio_receive(void *buffer, int *n_bytes, unsigned int timeout, int *strength)
{
	char *tmp;
	int avg_rssi = 0;
	int n = 0;
	int exception = 0;
  
	SPI_GET_REG_VALUE(CC2520_EXCFLAG0, exception);
	if (exception & (BM(CC2520_RX_OVERFLOW))) {  
		SPI_SET_REG_VALUE(CC2520_EXCFLAG0,0); //clear exception
		SPI_STROBE_REG(CC2520_SFLUSHRX); // Flush the RX FIFO 
		SPI_STROBE_REG(CC2520_SFLUSHRX); // twice (errata CC2520)
	}
	
	SPI_STROBE_REG(CC2520_SRXON);	// Turn on recept mode

	set_accurate_timer(timeout);
	while(!FIFO && !has_accurate_timer_expired()) ;	// Wait for a frame to come
	if (FIFO) { 
		// 	A frame is coming. While the frame is coming, we sample the RSSI
    	while(!FIFOP) {
			avg_rssi = get_rssi();
			n++;
		}
		
		if (FIFO && FIFOP) {
			*strength = avg_rssi / n;	// The final RSSI is the average of the received samples.

			SPI_READ_FIFO_BYTE(*n_bytes); // Get Payload length
			*n_bytes &= BASIC_RF_LENGTH_MASK; // Ignore MSB
			if(*n_bytes > 127) {
				// Frame length is incorrect.
				SPI_STROBE_REG(CC2520_SFLUSHRX);  // Flush the RX FIFO twice
				SPI_STROBE_REG(CC2520_SFLUSHRX);
				SPI_STROBE_REG(CC2520_SRFOFF);    // Turn off recept mode
				return RADIO_WRONG_LENGTH;
			}
			// Read  MAC's PDU
			SPI_QUICK_READ_FIFO(buffer,*n_bytes);
			  
			SPI_STROBE_REG(CC2520_SRFOFF);		// Turn off recept mode
			tmp = buffer;	
			
			// auto CRC verification
			if((tmp[*n_bytes-1] & 0x80) != 0) {
				return RADIO_SUCCESS;
			} else {
				return RADIO_CRC_ERROR;
			}
		} else {
			// If we are here, then the timeout expired and no frame were received
			SPI_STROBE_REG(CC2520_SRFOFF);// Turn off recept mode
			return RADIO_TIMEOUT;
		}
	} else {
		// If we are here, then the timeout expired and no frame were received.
		SPI_STROBE_REG(CC2520_SRFOFF);// Turn off recept mode
		return RADIO_TIMEOUT;
  	}
}

/*
 * Returns false if there is pending data in the RX buffer. Returns false otherwise.
 */
bool radio_rx_buffer_empty(void)
{
	int exception = 0;

	SPI_GET_REG_VALUE(CC2520_EXCFLAG0, exception);
	if (exception & (BM(CC2520_RX_OVERFLOW))) {  
		SPI_SET_REG_VALUE(CC2520_EXCFLAG0,0); //clear exception
		SPI_STROBE_REG(CC2520_SFLUSHRX); // Flush the RX FIFO 
		SPI_STROBE_REG(CC2520_SFLUSHRX); // twice (errata CC2520)
	}

	return (!FIFO || !FIFOP);
}

/*
 * Put the radio in RX mode
 */
void radio_set_rx_mode(void)
{
	SPI_STROBE_REG(CC2520_SRXON);	// Turn on recept mode
}

#endif

