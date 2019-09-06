/*
 * Simple MAC protocol leveraging WuRx MAC.
 * Its Works as follow:
 *
 * Transmitter TX:  ________|  WUB  |__|  DATA  |________________________
 * Transmitter RX:  _______________________________|  ACK  |_____________
 * Transmitter WuRx:_____________________________________________________
 *
 * Receiver TX:    ________________________________|  ACK  |_____________
 * Receiver RX:    ____________________|  DATA  |________________________
 * Receiver WuRx:  _________|  WUB  |____________________________________
 *
 * The transmitter wake up the received by sending a Wake Up Beacon (WUB)
 * 	containing the receiver address.
 * When the receiver is awaken, it turns on its main receiver in order to
 * 	receive data from the transmitter.
 * The transmitter waits for TA_DEL_WD before sending its data in order to
 * 	give time to the receiver to wake up and switch to receive state.
 * Once the data frame is transmitted, the transmitter switch to RX state in
 * 	order to receive an ACK frame, sent by the receiver when it has received
 * 	the data frame.
 *
 * The frames structures are as follow:
 *
 * 		WUB: 1 byte, Contains only the receiver address. The MSB must be 0 so only 7 bits
 * 	addresses are supported.
 *
 * 		DATA: contains a 1 byte source address, a 1 byte sequence number the payload of variable size.
 *  Note that the physical layer
 * 	add 1 byte length field and a 1 byte destination address. A preamble, sync bytes and a CRC
 * 	are also added by the physical layer. To configure these things, use the radio module.
 *
 * 		ACK: Contains the source address and the sequence number. Note that the physical layer
 * 	add 1 byte length field and a 1 byte destination address. A preamble, sync bytes and a CRC
 * 	are also added by the physical layer. To configure these things, use the radio module.
 *
 * 	In case of an error, binary exponential backoff is used for retrials.
 *
 * ****************** !! NOTE: THE CC112X radio chip driver is used.
 */

#ifdef RICER_WURX

#ifndef RICER_WURX__H
#define RICER_WURX__H

#include <sched/sched.h>
#include <drivers/hal_types.h>
#include <stdbool.h>

/*
 * Possible outcomes of a packet transmission
 */
#define RWM_TX_FIFO_FULL	0
#define RWM_TX_SUCCESS		1

/*
 * ********************************************************
 * MAC protocol constants that can be set to setup the MAC
 * behavior
 */
// RX Timeout. See CC112X p87 for time units
#define RX_TIMEOUT		1024u	// 5ms
// Maximum number of retrials
#define MAX_RETRIALS		2u
// MAX backoff
#define BACKOFF_BASE	8192u	//16s
// Packet are assumed to be of fixed size.
// This macro defines the size of one packet in bytes.
// This
#define PKT_SIZE			20u
// Size of the RX and RX FIFO (in packets)
#define RX_FIFO_SIZE		8u
#define TX_FIFO_SIZE		8u
// Maximum number of other nodes that will be connected
#define MAX_CON_NODES		10u

/*
 * Type of function called to generate a packet when the sink poll us and that the TX FIFO
 * is empty.
 *
 * If we can send data, this function should write the packet in the TX FIFO using rwmac_send() and return true.
 * Otherwise, it should return false.
 */
typedef bool (*gen_pkt_func)(void);

//
// FIFOs: use them carrefully
// Useful: increase fifo pointer
#define FIFO_INCR_PTR(x,S) (x = (x + 1) & (S-1))	// We assume here that S is a power of two
#define FIFO_IS_FULL(f,l,S) (((f == 0) && (l == (S-1))) || ((l+1) == f))
#define FIFO_IS_EMPTY(f,l)	(l == f)
// Fifo item struct
struct fifo_pkt_t
{
	uint8 address;
	// The first byte contains the sequence number (usefull only for the MAC)
	// The PKT_SIZE other bytes are for the user payload
	uint8 buffer[PKT_SIZE + 2];
};
extern struct fifo_pkt_t tx_fifo[TX_FIFO_SIZE];
extern struct fifo_pkt_t rx_fifo[RX_FIFO_SIZE];
extern uint8 tx_fifo_first;
extern uint8 tx_fifo_last;
extern uint8 rx_fifo_first;
extern uint8 rx_fifo_last;

/*
 * Initialize the MAC protocol.
 *
 * @param rx_fifo_cons: thread that should be scheduled when packets are received
 *
 * NOTE: This function intializes the WuRx. Don't do it externally.
 * NOTE: After the call of this function, WuRx interrupts are enabled.
 */
void rwmac_init(gen_pkt_func app_gen_pkt);

/*
 * Send a packet.
 *
 * - data: pointer to the data to send.
 * - dst_address: address of the receiver. Must be a 7 bits value.
 */
int rwmac_push_tx_fifo(uint8 *data, uint8 dst_address);

/*
 * Poll a node
 */
void rwmac_poll_node(uint8 address, struct pt *rx_fifo_cons);

/*
 * Enable/Disable the WuRx.
 * If the WuRx is disabled, no more data will be received.
 */
void rwmac_enable_wurx(void);
void rwmac_disable_wurx(void);

/* For debug
 */
uint8 rwmac_get_rx_seq(uint8 add);
uint8 rwmac_get_tx_seq(uint8 add);

#endif

#endif
