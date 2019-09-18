/*
 * Radio driver - Application interface.
 *
 * All radio drivers should implement this interface.
 */

#ifndef __CC12X_H
#define __CC12X_H

#include <stdbool.h>
#include <drivers/serial/spi/cc112x_spi.h>
#include <pt/pt.h>


// Supported modulations schemes
#define MOD_2_FSK		0
#define MOD_OOK			1
// Preamble setting: preamble size.
#define NUM_PREAMBLE_0B		0u
#define NUM_PREAMBLE_0_5B	1u
#define NUM_PREAMBLE_1B		2u
#define NUM_PREAMBLE_1_5B	3u
#define NUM_PREAMBLE_2B		4u
#define NUM_PREAMBLE_3B		5u
#define NUM_PREAMBLE_4B		6u
#define NUM_PREAMBLE_5B		7u
#define NUM_PREAMBLE_6B		8u
#define NUM_PREAMBLE_7B		9u
#define NUM_PREAMBLE_8B		10u
#define NUM_PREAMBLE_12B	11u
#define NUM_PREAMBLE_24B	12u
#define NUM_PREAMBLE_30B	13u
// Preamble setting: how a preamble looks like
#define WRD_PREAMBLE_1		0u	// 10101010...
#define WRD_PREAMBLE_2		1u	// 01010101...
#define WRD_PREAMBLE_3		2u	// 00110011...
#define WRD_PREAMBLE_4		3u	// 11001100...
// Synch word size
#define SYNC_MODE_NO	0u	// No synch word
#define SYNC_MODE_11	1u	// 11 bits
#define SYNC_MODE_16	2u	// 16 bits
#define SYNC_MODE_18	3u	// 18 bits
#define SYNC_MODE_24	4u	// 24 bits
#define SYNC_MODE_32	5u	// 32 bits
#define SYNC_MODE_16H	6u	// 16 bits (see datasheet for more details)
#define SYNC_MODE_16D	7u	// 16 bits (see datasheet for more details)
// Address filtering modes
#define ADDR_CHK_NO		0u	// No address check
#define ADDR_CHK_NB		1u	// Address check but no broadcast
#define ADDR_CHK_B1		2u	// Address check and 0x00 broadcast
#define ADDR_CHK_B2		3u	// Address check and 0x00 AND 0xFF broadcast
// CRC configuration
#define CRC_DIS			0u	// CRC disabled
#define CRC_EN1			1u	// CRC enabled. Initialized to 0xFFFF
#define CRC_EN2			2u	// CRC enabled. Initialized to 0x0000
// TX packet outcome
#define TXPKT_SUCCESS		0
#define TXPKT_CCA_ERR		1
#define TXPKT_FIFO_ERR		2
#define TXPKT_UNEXCP		3
#define TXPKT_WRONG_MODE	4
// RX packet outcome
#define RXPKT_SUCCESS		0
#define RXPKT_CRC_ERR		1
#define RXPKT_TIMEOUT		2
#define RXPKT_FIFO_ERR		3
#define RXPKT_LENGTH_ERR	4
#define RXPKT_ADDR_FAILED	5
#define RXPKT_UNEXCP		6
// CCA modes
#define CCA_NO		0	// Always gives clear channel indication
#define CCA_RSSI	1	// Gives clear channel when RSSI is below a threshold (default)
#define CCA_RX		2	// Gives clear channel unless receiving a packet
#define CCA_RSSI_RX	3	// Gives clear chabbel when RSSI is below a threshold and not receiving a packet
// WUB length
//#define WUB_LENGTH	1u


// modified by nour
#define WUB_LENGTH  2u

// Broadcast address
#define BROADCAST_ADDRESS	0x00u

/*
 * Init the radio
 *
 * @param clockDivider: prescalerValue - SMCLK/prescalerValue gives SCLK frequency
 *
 */
void cc112x_init(uint8 clockDivider);

/*
 * Go to sleep mode
 */
void cc112x_sleep(void);

/*
 * Go to idle mode
 */
void cc112x_idle(void);

/*
 * Set the modulation.
 *
 * NOTE: The CS threshold is set for each modulation scheme to value find in RFStudio.
 * The RSSI gain adjust is set to 0 in RF studio (reset value).
 *
 * @param mod: Must be MOD_2_FSK or MOD_OOK
 */
void cc112x_set_mod(uint8 mod);

/*
 * Set the symbol rate.
 *
 * SRATE_M is 20 bits wide given by srateM_19_16, srateM_15_8 and srateM_7_0.
 *
 * If srataE > 0, then SRATE = 32*10^6*((2^20 + SRATE_M)*2^srateE)/2^39 [ksps]
 * If srateE = 0, then SRATE = 32*10^6*(SRATE_M/2^38) [ksps]
 *
 * NOTE: srateM_19_16 and srateE are 4 bits values.
 *
 * NOTE: see datasheets p28 for more details
 */
void cc112x_set_symbol_rate(uint8 srateM_19_16, uint8 srateM_15_8, uint8 srateM_7_0, uint8 srateE);

/*
 * Set the output power.
 *
 * Output Power = (power_ramp + 1)/2 - 18 [dBm]
 *
 * power_ramp must be in the range [3,63]
 */
void cc112x_set_output_power(uint8 power_ramp);

/*
 * Set the preamble.
 *
 * @param num: size of the preamble, must be one of the NUM_PREAMBLE_XX macros
 * @param wrd: "shape" of the preamble, must be one of the WRD_PREAMBLE_X macros
 */
void cc112x_set_preamble(uint8 num, uint8 wrd);

/*
 * Set the sync word mode
 *
 * @param mode: must be SYNC_MODE_XX
 *
 */
void cc112x_set_sync_mode(uint8 mode);

/*
 * Enable/Disbale address filtering.
 *
 * @param mode: must be one of the ADDR_CHECK_X
 * @param addr: My address. Used only if address filtering is enabled.
 */
void cc112x_set_addr_check(uint8 mode, uint8 addr);

/*
 * Enable/Disable CRC
 *
 * NOTE: if CRC is switched from OFF to ON, the RX FIFO will be flushed
 *
 * @param mode: must be CRC_XX macros
 */
void cc112x_set_crc(uint8 mode);

/*
 * Set CCA mode
 *
 * @param mode: Must be one of CCA_NO/CCA_RSSI/CCA_RX/CCA_RSSI_RX
 */
void cc112x_set_cca(uint8 mode);

/*
 * Set the RX termination timeout.
 *
 * See userguide of CC112X p87
 */
void cc112x_set_rx_timeout(uint16 timeout);

/*
 * Receive a packet.
 *
 * The packet format is as follows:
 *               |-------------------------------------------------------|
 *               |           |           |           |         |         |
 *               | Length    | Address   | Data 0    | ....... |Data N   |
 *               |           |           |           |         |         |
 *               |-------------------------------------------------------|
 *
 * @param buffer: where to put the received data
 * @param length: will be set to the length of the data payload (not including the length and the address)
 * @param address: will be set to the sender address
 * @param timeout: The time during which we wait for packets. 0 if no timeout. The accurate timer of the timer module is used.
 * 	See the documentation of this module for details about the time unit.
 *
 * Returns RXPKT_SUCCESS/RXPKT_CRC_ERR/RXPKT_TIMEOUT/RXPKT_FIRO_ERR/RXPKT_LENGTH_ERR/RXPKT_ADDR_FAILED/RXPKT_UNEXCP depending on the outcome
 *
 *  When this function returns, the radio will be in IDLE mode.
 */
int cc112x_rx_pkt(uint8* buffer, uint8 *length, uint8 *address, bool timeout);

/*
 * Transmit a packet.
 *
 * The packet format is as follows:
 *               |-------------------------------------------------------|
 *               |           |           |           |         |         |
 *               | Length    | Address   | Data      | ....... |Data     |
 *               |           |           |           |         |         |
 *               |-------------------------------------------------------|
 *                                         data[0]            data[length-1]
 *
 *   @param data   : Pointer to start of the packet buffer.
 *   @param length: Length of the payload, without counting the "Length" and "Address" fields.
 *
 * Returns TXPKT_SUCCESS/TXPKT_CCA_ERR/TXPKT_FIFO_ERR/TXPKT_UNEXCP/TXPKT_WRONG_MODE depending on the outcome
 *
 *  When this function returns, the radio will be in IDLE mode.
 */
int cc112x_tx_pkt(uint8 *data, uint8 length, uint8 address);

/*
 * Transmit a WUB.
 * Must be in WUB mode.
 * A wub contains only a 1 byte word.
 *
 * @param data: WUB payload.
 *
 * Returns TXPKT_SUCCESS/TXPKT_CCA_ERR/TXPKT_FIFO_ERR/TXPKT_UNEXCP/TXPKT_WRONG_MODE depending on the outcome
 *
 *  When this function returns, the radio will be in IDLE mode.
 */
int cc112x_tx_wub(uint8 data[]);

/*
 * Switch to data mode.
 * This mode must be used to transmit/receive data.
 * Transmit power: 0 dBm
 * Modulation: 2-FSK
 * 3 Bytes preamble (0xAA)
 * 32 bits sync word
 * CRC enabled
 * Variable payload length
 */
void cc112x_data_mode(void);

/*
 * Switch to WUB mode.
 * This mode must be used to transmit WUBs.
 * Transmit power: 15 dBm
 * Modulation: ASK/OOK
 * No preamble
 * No sync bytes
 * No CRC
 * Fixed payload length of 1 byte
 */
void cc112x_wub_mode(void);

/*
 * Go to the continuous RX mode. The radio is set in the RX state.
 * This function is non blocking, the radio will stay in RX state after the function returns.
 * If a packet is successfully received, the thread set using the function 'cc112x_set_ctn_thr' will be scheduled.
 * If a cc112x_tx* is called, the radio will be in idle state after the call.
 * Calling cc112x_rx_pkt() will fail.
 * To leave the continous RX state, call cc112x_sleep().
 *
 * @param rcv_thr: thread to schedule when a packet is successfully recieved.
 */
void cc112x_continuous_rx(void);

/*
 * Set the thread that should be scheduled when a packet is successfully received in continuous RX state.
 */
void cc112x_set_ctn_thr(struct pt* ctn_rx_thr);

/*
 * Read the next packet from the RX transceiver buffer.
 * Useful in continuous RX mode.
 * Returns true if the data was successfully read, false otherwise.
 */
bool cc112x_pull_pkt_rxfifo(uint8* buffer, uint8 *length, uint8 *address);

/*
 * Returns true if the RX fifo is empty, false otherwise.
 */
bool cc112x_rxfifo_empty(void);


#endif
