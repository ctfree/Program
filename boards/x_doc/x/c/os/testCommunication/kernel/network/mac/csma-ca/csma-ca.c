/*
 * Implementation of the CSMA/CA protocol from IEEE 802.15.4 MAC layer.
 *
 * ****************** !! NOTE: THE CC112X radio chip driver is used.
 */

#ifdef CSMACA

#include <network/mac/csma-ca/csma-ca.h>
#include <drivers/radio/cc112x.h>
#include <drivers/wurx/wurx.h>
#include <tools/timer/timer.h>
#include <stddef.h>
#include <string.h>
#include <config.h>
#include <stdlib.h>
#include <stdbool.h>

// Frames Types (2 bits)
#define ACK			0b01000000u
#define DATA		0b10000000u


// Frame length
#define ACK_SIZE	1u

// ************************************************************
// FIFO variables: shared with the app threads
struct fifo_pkt_t tx_fifo[TX_FIFO_SIZE];
struct fifo_pkt_t rx_fifo[RX_FIFO_SIZE];
uint8 tx_fifo_first = 0u;
uint8 tx_fifo_last = 0u;
uint8 rx_fifo_first = 0u;
uint8 rx_fifo_last = 0u;

// ************************************************************
// Private variables
// Thread to schedule when the RX FIFO is not empty
static struct pt *_rx_fifo_cons;

// Sending thread
static struct pt _sender_thread_pt;

// Receiving thread
static struct pt _recv_thread_pt;

// Some state we need to remember about
enum state_t
{
	READY,
	WAITING_BACKOFF,
};
static enum state_t _current_state = READY;

// ------------------------------------------------------
// Sequence numbers for RX and TX management
struct seq_num_t
{
	uint8 add;
	uint8 seq;
};
static struct seq_num_t _rx_seqs[MAX_CON_NODES] = {0,0};
static struct seq_num_t _tx_seqs[MAX_CON_NODES] = {0,0};

// Numner of retrying
static uint8 _retries = 0u;

// Get the next RX sequence number
static uint8 get_next_rx_seq(uint8 add)
{
	uint8 i;
	for (i = 0u; i < MAX_CON_NODES; i++) {
		if (_rx_seqs[i].add == add){
			return _rx_seqs[i].seq;
		} else if (_rx_seqs[i].add == 0u) {
			// No point to go further
			break;
		}
	}
	// If we are here then the node was unknown. Adding it
	_rx_seqs[i].add = add;
	return (_rx_seqs[i].seq = 0u);
}

// Set the RX seq number
static void set_rx_seq(uint8 add, uint8 seq)
{
	uint8 i;
	for (i = 0u; i < MAX_CON_NODES; i++) {
		if (_rx_seqs[i].add == add){
			_rx_seqs[i].seq = seq;
			return;
		} else if (_rx_seqs[i].add == 0u) {
			// No point to go further
			break;
		}
	}
	// If we are here then the node was unknown. Adding it
	_rx_seqs[i].add = add;
	_rx_seqs[i].seq = seq;
}

// Get and increase the TX seq number
static uint8 get_incr_tx_seq(uint8 add)
{
	uint8 i;
	for (i = 0u; i < MAX_CON_NODES; i++) {
		if (_tx_seqs[i].add == add){
			uint8 seq = _tx_seqs[i].seq;
			_tx_seqs[i].seq = (_tx_seqs[i].seq + 1) & 0xFFu;
			return seq;
		} else if (_tx_seqs[i].add == 0u) {
			// No point to go further
			break;
		}
	}
	// If we are here then the node was unknown. Adding it
	_tx_seqs[i].add = add;
	_tx_seqs[i].seq = 1u;
	return 0u;
}

/*
 * Sender thread.
 *
 * This thread is responsible for pulling packet from the TX FIFO and sending them.
 */
static PT_THREAD(sender_thread(void *args))
{
	int r;
	uint8 buf[PKT_SIZE+2], length, address, type, max_backoff, backoff;

	PT_BEGIN(&_sender_thread_pt);

	for ( ;; ) {

		cc112x_continuous_rx();
		WAIT_EVENT(&_sender_thread_pt);

		// Next trial
		next_trial:

		// Backoff before sending
		max_backoff = EXP_BACKOFF_BASE << _retries;
		backoff = rand() & (max_backoff-1u);
		_current_state = WAITING_BACKOFF;
		set_one_shot_timer_sleep(backoff, &_sender_thread_pt);
		cc112x_continuous_rx();
		WAIT_EVENT(&_sender_thread_pt);

		cc112x_idle();

		// Enabling the CCA
		cc112x_set_cca(CCA_RSSI);
		// Sending the data
		r = cc112x_tx_pkt(tx_fifo[tx_fifo_first].buffer, PKT_SIZE+2, tx_fifo[tx_fifo_first].address);
		if (r != TXPKT_SUCCESS) {
			// Error when sending the data frame
			goto retry;
		}
		// Set RX timer to default value
		cc112x_set_rx_timeout(RX_TIMEOUT);
		// Waiting for the ACK
		r = cc112x_rx_pkt(buf, &length, &address, true);
		if (r != RXPKT_SUCCESS) {
			// Error when receiving the ACK
			goto retry;
		}
		type = buf[0];
		if (type != ACK) {
			// Receive unexpected frame
			goto retry;
		}
		// If we are here, everything went fine ! We can send the next packet if any
		_retries = 0u;
		_current_state = READY;
		FIFO_INCR_PTR(tx_fifo_first, TX_FIFO_SIZE);
		if (!FIFO_IS_EMPTY(tx_fifo_first, tx_fifo_last)) {
			goto next_trial;
		} else {
			continue;
		}

		// Retrying. If we execute this then something went wrong.
		retry:
		if (_retries == MAX_RETRIALS) {
			// We already tried to many times. Dropping this packet and trying the next one
			FIFO_INCR_PTR(tx_fifo_first, TX_FIFO_SIZE);
			_retries = 0u;
			_current_state = READY;
			if (!FIFO_IS_EMPTY(tx_fifo_first, tx_fifo_last)) {
				goto next_trial;
			}
		} else {
			_retries++;
			goto next_trial;
		}
	}

	PT_END(&_sender_thread_pt);
}

/*
 * Receiving thread.
 *
 * This thread is schedules by the WuRx driver everytime an interrupt from the WuRx arises.
 */
static PT_THREAD(recv_thread(void *args))
{
	uint8 misc, length, address, type, seq, exc_seq;

	PT_BEGIN(&_recv_thread_pt);

	for ( ;; )
	{
		cc112x_continuous_rx();
		WAIT_EVENT(&_recv_thread_pt);

		cc112x_idle();

		while (!cc112x_rxfifo_empty()) {
			if (!cc112x_pull_pkt_rxfifo(rx_fifo[rx_fifo_last].buffer, &length, &address)) {
				break;
			}
			// Checking the type
			type = rx_fifo[rx_fifo_last].buffer[0];
			if (type != DATA) {
				goto end_rx;
			}
			// Sending the ACK
			misc = ACK;
			cc112x_set_cca(CCA_NO);
			cc112x_tx_pkt(&misc, ACK_SIZE, address);
			// Check the sequence number
			seq = rx_fifo[rx_fifo_last].buffer[1];
			exc_seq = get_next_rx_seq(address);
			if (seq != exc_seq - 1) {
				// Not received yet
				set_rx_seq(address, seq);
				// If we are here, everything went fine.
				rx_fifo[rx_fifo_last].address = address;
				FIFO_INCR_PTR(rx_fifo_last, RX_FIFO_SIZE);
			}
		}

		end_rx:

		// If the RX fifo is not empty, the RX FIFO consummer thread is scheduled
		if (!FIFO_IS_EMPTY(rx_fifo_first, rx_fifo_last)) {
			schedule_thread(_rx_fifo_cons, true);
		}
	}

	PT_END(&_recv_thread_pt);
}

/*
 * Initialize the MAC protocol.
 *
 * @param device_addr: address of the device
 * @param rx_fifo_cons: thread that should be scheduled when packets are received
 *
 * NOTE: This function intializes the WuRx. Don't do it externally.
 * NOTE: After the call of this function, WuRx interrupts are enabled.
 */
void csmaca_init(struct pt *rx_fifo_cons)
{
	_rx_fifo_cons = rx_fifo_cons;

	// Initalizes the CC1120
	cc112x_init(2u);

	// Enable the device address filtering and set the device address
	cc112x_set_addr_check(ADDR_CHK_B1, SELF_MAC_ADDRESS);

	// Initializing the sender thread
	PT_INIT(&_sender_thread_pt, sender_thread, NULL);
	register_thread(&_sender_thread_pt, true);

	// Initializing the receiving thread only if a packet consumer thread is specified
	if (rx_fifo_cons != NULL) {
		PT_INIT(&_recv_thread_pt, recv_thread, NULL);
		register_thread(&_recv_thread_pt, true);
		cc112x_set_ctn_thr(&_recv_thread_pt);
	}

	// Putting the radio in continuous listening mode
	cc112x_continuous_rx();

	// Initializing random number generator
	srand(SELF_MAC_ADDRESS);
}

/*
 * Send a packet.
 *
 * - data: pointer to the data to send.
 * - length: length of the data payload.
 * - dst_address: address of the receiver. Must be a 7 bits value.
 */
int csmaca_send(uint8 *data, uint8 dst_address)
{

	// Checking that the TX FIFO is not full
	if (!FIFO_IS_FULL(tx_fifo_first, tx_fifo_last, TX_FIFO_SIZE)) {
		// Adding the data to the TX FIFO
		tx_fifo[tx_fifo_last].address = dst_address;
		tx_fifo[tx_fifo_first].buffer[0] = DATA;
		tx_fifo[tx_fifo_last].buffer[1] = get_incr_tx_seq(dst_address);
		memcpy(&(tx_fifo[tx_fifo_last].buffer[2]), data, PKT_SIZE);
		FIFO_INCR_PTR(tx_fifo_last, TX_FIFO_SIZE);
	}

	if (_current_state == READY) {
		schedule_thread(&_sender_thread_pt, true);
	}

	return SWM_TX_SUCCESS;
}

/* For debug
 */
uint8 csmaca_get_rx_seq(uint8 add)
{
	uint8 i;
	for (i = 0u; i < MAX_CON_NODES; i++) {
		if (_rx_seqs[i].add == add){
			return _rx_seqs[i].seq;
		} else if (_rx_seqs[i].add == 0u) {
			// No point to go further
			break;
		}
	}
	return 0u;
}

uint8 csmaca_get_tx_seq(uint8 add)
{
	uint8 i;
	for (i = 0u; i < MAX_CON_NODES; i++) {
		if (_tx_seqs[i].add == add){
			return _tx_seqs[i].seq;
		} else if (_tx_seqs[i].add == 0u) {
			// No point to go further
			break;
		}
	}
	return 0u;
}

#endif
