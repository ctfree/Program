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

#ifdef TICER_WURX

#include <network/mac/ticer-wurx/ticer-wurx.h>
#include <drivers/radio/cc112x.h>
#include <drivers/wurx/wurx.h>
#include <tools/timer/timer.h>
#include <stddef.h>
#include <string.h>
#include <config.h>
#include <stdlib.h>

// Frames Types (2 bits)
#define ACK			0b01000000u
#define DATA		0b10000000u

// Frame length
#define ACK_SIZE	1u
#define CTS_SIZE	1u

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

// Some state we need to remember about
enum state_t
{
	READY,
	WAITING_TO_RETRY,
};
static enum state_t _current_state = READY;

// Sending thread
static struct pt _sender_thread_pt;

// Receiving thread
static struct pt _recv_thread_pt;

// Numner of retrying
static uint8 _retries = 0u;

// ------------------------------------------------------
// Sequence numbers for RX and TX management
struct seq_num_t
{
	uint8 add;
	uint8 seq;
};
static struct seq_num_t _rx_seqs[MAX_CON_NODES] = {0,0};
static struct seq_num_t _tx_seqs[MAX_CON_NODES] = {0,0};

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
	uint8 buf[PKT_SIZE+2], length, address, type;

	PT_BEGIN(&_sender_thread_pt);

	for ( ;; ) {

		cc112x_sleep();
		WAIT_EVENT(&_sender_thread_pt);

		send_pkt:
		/* If the TX FIFO is not empty, we try to send the packet at the top */
		if (FIFO_IS_EMPTY(tx_fifo_first, tx_fifo_last)) {
			continue;
		}
		// First we send a WUB
		cc112x_wub_mode();
		// Enabling CCA
		//cc112x_set_cca(CCA_RSSI);
		// NOTE: for Skopje Demo
		cc112x_set_cca(CCA_NO);
		uint8 wub[] = {tx_fifo[tx_fifo_first].address};
		r = cc112x_tx_wub(wub);
		if (r != TXPKT_SUCCESS) {
			goto retry;
		}

		// Switch to data mode
		cc112x_data_mode();
		// Disabling CCA
		cc112x_set_cca(CCA_NO);
		// Sending the data
		r = cc112x_tx_pkt(tx_fifo[tx_fifo_first].buffer, PKT_SIZE+2, tx_fifo[tx_fifo_first].address);
		if (r != TXPKT_SUCCESS) {
			goto retry;
		}
		// Waiting for the ACK
		r = cc112x_rx_pkt(buf, &length, &address, true);
		if (r != RXPKT_SUCCESS) {
			goto retry;
		}
		type = buf[0];
		if (type != ACK) {
			goto retry;
		}
		// If we are here, everything went fine ! We can send the next packet if any
		FIFO_INCR_PTR(tx_fifo_first, TX_FIFO_SIZE);
		_retries = 0u;
		_current_state = READY;

		goto send_pkt;

		// Retrying. If we execute this then something went wrong.
		retry:
		if (_retries == MAX_RETRIALS) {
			// We already tried to many times. Dropping this packet and trying the next one
			FIFO_INCR_PTR(tx_fifo_first, TX_FIFO_SIZE);
			_retries = 0u;
			_current_state = READY;
			goto send_pkt;
		} else {
			uint16 max_backoff = EXP_BACKOFF_BASE << _retries;
			uint16 backoff = rand() & (max_backoff-1u);
			_retries++;
			set_one_shot_timer_sleep(backoff, &_sender_thread_pt);
			_current_state = WAITING_TO_RETRY;
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
	uint8 r, misc, length, address, type, seq, exc_seq;

	PT_BEGIN(&_recv_thread_pt);

	for ( ;; )
	{
		cc112x_sleep();
		WAIT_EVENT(&_recv_thread_pt);

		// WuRx interrupts are disabled by the WuRx driver when this thread is scheduled

		// Receive some data. Useless here
		//addr = 0u;
		//while (WURX_DATA_PIN);	// Wait the low bit
		//int j;
		//for (j = 0; j < 355; j++);
		//for (uint8 i = 0u; i < 8u; i++) {
		//	addr <<= 1;
		//	if (WURX_DATA_PIN) {
		//		addr += 1;
		//	}
		//	for (j = 0; j < 230; j++);
		//}

		// Checking if the FIFO is full
		if (FIFO_IS_FULL(rx_fifo_first, rx_fifo_last, RX_FIFO_SIZE)) {
			// The RX FIFO is full
			goto end_rx;
		}
		// Receiving the data frame
		r = cc112x_rx_pkt(rx_fifo[rx_fifo_last].buffer, &length, &address, true);
		if (r != RXPKT_SUCCESS) {
			goto end_rx;
		}
		// Sending the ACK
		// Disabling CCA
		cc112x_set_cca(CCA_NO);
		type = rx_fifo[rx_fifo_last].buffer[0];
		if (type != DATA) {
			goto end_rx;
		}
		seq = rx_fifo[rx_fifo_last].buffer[1];
		// Check the sequence number
		exc_seq = get_next_rx_seq(address);
		if (seq != exc_seq - 1) {
			// Not received yet
			set_rx_seq(address, seq);
			// If we are here, everything went fine.
			rx_fifo[rx_fifo_last].address = address;
			FIFO_INCR_PTR(rx_fifo_last, RX_FIFO_SIZE);
		}
		misc = ACK;
		r = cc112x_tx_pkt(&misc, CTS_SIZE, address);
		if (r != TXPKT_SUCCESS) {
			goto end_rx;
		}

		end_rx:
		// Enable the WuRx IT before calling the user handler
		ENABLE_WURX_IT;

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
void twmac_init(struct pt *rx_fifo_cons)
{
	_rx_fifo_cons = rx_fifo_cons;

	// Initalizes the CC1120
	cc112x_init(2u);

	// Enable the device address filtering and set the device address
	cc112x_set_addr_check(ADDR_CHK_NB, SELF_MAC_ADDRESS);

	// Set the RX timeout
	cc112x_set_rx_timeout(RX_TIMEOUT);

	// Putting radio chip in sleep state
	cc112x_sleep();

	// Initializing the sender thread
	PT_INIT(&_sender_thread_pt, sender_thread, NULL);
	register_thread(&_sender_thread_pt, true);

	// Initializing the sender thread
	PT_INIT(&_recv_thread_pt, recv_thread, NULL);
	register_thread(&_recv_thread_pt, true);

	// Initializing the WuRx
	wurx_init(&_recv_thread_pt);

	// Enabling the WuRx interrupt
	ENABLE_WURX_IT;
}

/*
 * Enable/Disable the WuRx.
 * If the WuRx is disabled, no more data will be received.
 */
void twmac_enable_wurx(void)
{
	ENABLE_WURX_IT;
}

void twmac_disable_wurx(void)
{
	DISABLE_WURX_IT;
}

/*
 * Send a packet.
 *
 * - data: pointer to the data to send.
 * - length: length of the data payload.
 * - dst_address: address of the receiver. Must be a 7 bits value.
 */
int twmac_send(uint8 *data, uint8 dst_address)
{
	// First we disable WuRx interrupts
	DISABLE_WURX_IT;

	// Checking that the TX FIFO is not full
	if (FIFO_IS_FULL(tx_fifo_first, tx_fifo_last, TX_FIFO_SIZE)) {
		ENABLE_WURX_IT;
		return TWM_TX_FIFO_FULL;
	}

	// Adding the data to the TX FIFO
	tx_fifo[tx_fifo_last].address = dst_address;
	tx_fifo[tx_fifo_last].buffer[0] = DATA;
	tx_fifo[tx_fifo_last].buffer[1] = get_incr_tx_seq(dst_address);
	memcpy(&(tx_fifo[tx_fifo_last].buffer[2]), data, PKT_SIZE);
	FIFO_INCR_PTR(tx_fifo_last, TX_FIFO_SIZE);

	// ENABLE the WURX IT
	ENABLE_WURX_IT;

	// If the TX FIFO was not empty, then the sending thread is alwready aware that there are stuff to
	// send. No need to wake it up.
	// Otherwise, we need to schedule it
	if (_current_state == READY) {
		schedule_thread(&_sender_thread_pt, true);
	}

	return TWM_TX_SUCCESS;
}

/* For debug
 */
uint8 twmac_get_rx_seq(uint8 add)
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

uint8 twmac_get_tx_seq(uint8 add)
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

