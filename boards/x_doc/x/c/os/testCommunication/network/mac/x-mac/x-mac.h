/*
 * Implementation of the X-MAC protocol variation, similar to the one find in the UPMA package
 * of Tiny OS.
 *
 * ****************** !! NOTE: THE CC112X radio chip driver is used.
 */

#ifdef XMAC

#ifndef XMAC_H
#define XMAC_H

#include <sched/sched.h>
#include <drivers/hal_types.h>

/*
 * Possible outcomes of a packet transmission
 */
#define XM_TX_FIFO_FULL	0
#define XM_TX_SUCCESS		1

/*
 * ********************************************************
 * MAC protocol constants that can be set to setup the MAC
 * behavior
 */
// RX Timeout. See CC112X p87 for time units
#define RX_TIMEOUT		1024u // 5ms
#define WUP_TIMEOUT		4710u	// 23ms	// Wake up time when checking if a packet is arriving
// Maximum number of retrials
#define MAX_RETRIALS		2u
// Binary exponential backoff base. See CC112X p87 for time units
// Value: 50ms
#define BACKOFF_BASE	8192u	// 16s
// Packet are assumed to be of fixed size.
// This macro defines the size of one packet in bytes.
#define PKT_SIZE			20u
// Size of the RX and RX FIFO (in packets)
#define RX_FIFO_SIZE		8u
#define TX_FIFO_SIZE		8u
// Maximum number of other nodes that will be connected
#define MAX_CON_NODES		10u
// Periodic wake up schedule for receivers
#define RCV_WAKEUP_INTERVAL	128u	// 250ms
//#define RCV_WAKEUP_INTERVAL	256u	// 500ms
// Maximum number of packet transmissions without receiving an ACK
//	before retrying.
// Computed from the wake up interval of the receivers and the duration
//	of a data packet transmission.
#define MAX_PKT_TX	13u	// 250ms
//#define MAX_PKT_TX	26u	// 500ms

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
	uint8 buffer[PKT_SIZE + 2];	// |TYPE|SEQ|DATA...
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
 * @param device_addr: address of the device
 * @param rx_fifo_cons: thread that should be scheduled when packets are received
 *
 * NOTE: If rx_fifo_cons is NULL, then the node is assumed to note receive packets. Then,
 * 	it will not wake up to receive data in order to save energy.
 */
void xmac_init(struct pt *rx_fifo_cons);

/*
 * Send a packet.
 *
 * - data: pointer to the data to send.
 * - dst_address: address of the receiver. Must be a 7 bits value.
 */
int xmac_send(uint8 *data, uint8 dst_address);

/* For debug
 */
uint8 xmac_get_rx_seq(uint8 add);
uint8 xmac_get_tx_seq(uint8 add);

#endif

#endif
