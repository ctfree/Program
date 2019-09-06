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

#include <network/mac/ricer-wurx/ricer-wurx.h>
#include <drivers/radio/cc112x.h>
#include <drivers/wurx/wurx.h>
#include <tools/timer/timer.h>
#include <stddef.h>
#include <string.h>
#include <config.h>
#include <stdlib.h>
#include <stdbool.h>

// Frames Types (2 bits)
#define CTS			0b00000000u
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

// Sending thread
static struct pt _sender_thread_pt;

// Receiving thread pool
#define RECV_THREAD_POOL_SIZE	10u
struct recv_thread_poll_t {
	struct pt thread;
	bool used;
	uint8 node_to_poll_add;	// Node to poll address
	int retries;
	struct pt *cons_thread;
};
static struct recv_thread_poll_t _recv_thread_pool[RECV_THREAD_POOL_SIZE];

// ------------------------------------------------------
// Sequence numbers for RX and TX management
struct seq_num_t
{
	uint8 add;
	uint8 seq;
};
static struct seq_num_t _rx_seqs[MAX_CON_NODES] = {0,0};
static struct seq_num_t _tx_seqs[MAX_CON_NODES] = {0,0};

// Function used to generate packets when the sink poll the node and the TX FIFO is empty.
static gen_pkt_func _app_gen_pkt = NULL;

// Get the next RX sequence number
#define SEQ_MASK 3
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
			_tx_seqs[i].seq = (_tx_seqs[i].seq + 1) & SEQ_MASK;
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
 *
 * This thread is scheduled when a WuRx interrupt arrises.
 *
 * If the TX FIFO contains at least one packet, then the oldest packet is sent.
 * If the TX FIFO is empty, then we ask the app to generate a packet. If a packet could
 * 	successfully be generated, then it is sent. Otherwise, the sending process is aborted.
 */
static PT_THREAD(sender_thread(void *args))
{
	uint8 seq;

	PT_BEGIN(&_sender_thread_pt);

	for ( ;; ) {

		cc112x_sleep();
		WAIT_EVENT(&_sender_thread_pt);

		// WuRx interrupts are disabled by the WuRx driver when this thread is scheduled

		// Reading the sequence number
		seq = 0u;
		while (WURX_DATA_PIN);	// Wait the low bit
		int j;
		for (j = 0; j < 355; j++);
		for (uint8 i = 0u; i < 8u; i++) {
			seq <<= 1;
			if (WURX_DATA_PIN) {
				seq += 1;
			}
			for (j = 0; j < 230; j++);
		}

		// Erase from the TX buffer the packets that were succesfully sent or dropped
		while ((!FIFO_IS_EMPTY(tx_fifo_first, tx_fifo_last)) && (tx_fifo[tx_fifo_first].buffer[1] != seq)) {
			FIFO_INCR_PTR(tx_fifo_first, TX_FIFO_SIZE);
		}

		// Generating the packet to send
		while (FIFO_IS_EMPTY(tx_fifo_first, tx_fifo_last)) {
			if (!_app_gen_pkt()) {
				// The app could not generate a packet. Abort.
				goto end_tx;
			}
			if (tx_fifo[tx_fifo_first].buffer[1] != seq) {
				FIFO_INCR_PTR(tx_fifo_first, TX_FIFO_SIZE);
			}
		}

		// Disabling CCA
		cc112x_set_cca(CCA_NO);
		// Sending the data
		cc112x_tx_pkt(tx_fifo[tx_fifo_first].buffer, PKT_SIZE+2, tx_fifo[tx_fifo_first].address);

		end_tx:
		// Enabling WuRx IT
		ENABLE_WURX_IT;
	}

	PT_END(&_sender_thread_pt);
}

/*
 * Receiving thread.
 *
 * This thread is scheduled to receive data. It schedules the receiving app thread when the receiving process
 * 	end (successfully or not). The ending status of the receiving process can be find out by a call to
 * 	rwmac_rcv_status().
 */
static PT_THREAD(recv_thread(void *args))
{
	uint8 r, length, type, seq, exc_seq;
	struct recv_thread_poll_t *recv_th = (struct recv_thread_poll_t*)args;

	PT_BEGIN(&(recv_th->thread));

	for ( ;; ) {

		cc112x_sleep();
		WAIT_EVENT(&(recv_th->thread));

		// Checking if the FIFO is full
		if (FIFO_IS_FULL(rx_fifo_first, rx_fifo_last, RX_FIFO_SIZE)) {
			// The RX FIFO is full. Cannot receive anymore packets
			break;
		}

		// Sending a WUB to wake up the node
		cc112x_wub_mode();
		// Enabling CCA
		cc112x_set_cca(CCA_RSSI);
		// Sending the wake-up beacon
		exc_seq = get_next_rx_seq(recv_th->node_to_poll_add);	// Expected sequence number and increase it for next
		uint8 wub[] = {	recv_th->node_to_poll_add,		// Address of the node to wake-up
						exc_seq };	// Expected sequence number
		r = cc112x_tx_wub(wub);
		if (r != TXPKT_SUCCESS) {
			goto retry;
		}

		// Switch to data mode
		cc112x_data_mode();

		// Receiving the data frame
		uint8 addr;
		r = cc112x_rx_pkt(rx_fifo[rx_fifo_last].buffer, &length, &addr, true);
		if (r != RXPKT_SUCCESS) {
			goto retry;
		}
		type = rx_fifo[rx_fifo_last].buffer[0];
		if (type != DATA) {
			goto retry;
		}
		seq = rx_fifo[rx_fifo_last].buffer[1];
		// Check the sequence number
		if (seq == exc_seq) {
			// Everything went fine
			set_rx_seq(recv_th->node_to_poll_add, (exc_seq + 1) & SEQ_MASK);	// Increasing sequence number
			rx_fifo[rx_fifo_last].address = recv_th->node_to_poll_add;
			FIFO_INCR_PTR(rx_fifo_last, RX_FIFO_SIZE);
		} else {
			// Unexpected sequence number received. Trying again
			goto retry;
		}

		recv_th->used = false;

		// Scheduling the consumer
		schedule_thread(recv_th->cons_thread);

		continue;

		retry:
		if (recv_th->retries == MAX_RETRIALS) {
			// We already tried to many times. Dropping this packet.
			set_rx_seq(recv_th->node_to_poll_add, (exc_seq + 1) & SEQ_MASK);	// Increasing sequence numberrecv_th->node_to_poll_add
			// This thread is now available
			recv_th->used = false;
			recv_th->retries = 0u;
			schedule_thread(recv_th->cons_thread);
		} else {
			uint16 backoff = rand() & (BACKOFF_BASE-1u);
			if (backoff < 512u) {	// Minimal backoff
				backoff = 512u;
			}
			recv_th->retries++;
			set_one_shot_timer_sleep(backoff, &(recv_th->thread));
		}
	}

	PT_END(&(recv_th->thread));
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
void rwmac_init(gen_pkt_func app_gen_pkt)
{
	_app_gen_pkt = app_gen_pkt;

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
	register_thread(&_sender_thread_pt);

	// Initializing the receiving thread
	int i;
	for (i = 0; i < RECV_THREAD_POOL_SIZE; i++) {
		PT_INIT(&(_recv_thread_pool[i].thread), recv_thread, &(_recv_thread_pool[i]));
		register_thread(&(_recv_thread_pool[i].thread));
		_recv_thread_pool[i].used = false;
	}

	// Initializing the WuRx
	wurx_init(&_sender_thread_pt);

	// Initializing random number generator
	srand(SELF_MAC_ADDRESS);

	// Enabling the WuRx interrupt
	ENABLE_WURX_IT;
}

/*
 * Enable/Disable the WuRx.
 * If the WuRx is disabled, no more data will be received.
 */
void rwmac_enable_wurx(void)
{
	ENABLE_WURX_IT;
}

void rwmac_disable_wurx(void)
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
int rwmac_push_tx_fifo(uint8 *data, uint8 dst_address)
{
	// First we disable WuRx interrupts
	DISABLE_WURX_IT;

	// Checking that the TX FIFO is not full
	if (FIFO_IS_FULL(tx_fifo_first, tx_fifo_last, TX_FIFO_SIZE)) {
		ENABLE_WURX_IT;
		return RWM_TX_FIFO_FULL;
	}

	// Adding the data to the TX FIFO
	tx_fifo[tx_fifo_last].address = dst_address;
	tx_fifo[tx_fifo_last].buffer[0] = DATA;	// Type
	tx_fifo[tx_fifo_last].buffer[1] = get_incr_tx_seq(dst_address);	// Seq
	memcpy(&(tx_fifo[tx_fifo_last].buffer[2]), data, PKT_SIZE);
	FIFO_INCR_PTR(tx_fifo_last, TX_FIFO_SIZE);

	// ENABLE the WURX IT
	//ENABLE_WURX_IT;

	return RWM_TX_SUCCESS;
}

/*
 * Poll a node
 */
void rwmac_poll_node(uint8 address, struct pt *rx_fifo_cons)
{
	DISABLE_WURX_IT;

	int i;
	struct recv_thread_poll_t *avl = NULL;
	for (i = 0; i < RECV_THREAD_POOL_SIZE; i++) {
		if (!_recv_thread_pool[i].used) {
			avl = &(_recv_thread_pool[i]);
		} else {
			if (_recv_thread_pool[i].node_to_poll_add == address) {
				ENABLE_WURX_IT;
				return;
			}
		}
	}
	if (avl) {
		avl->used = true;
		avl->node_to_poll_add = address;
		avl->retries = 0;
		avl->cons_thread = rx_fifo_cons;
		schedule_thread(&(avl->thread));
	}

	ENABLE_WURX_IT;
}

/* For debug
 */
uint8 rwmac_get_rx_seq(uint8 add)
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

uint8 rwmac_get_tx_seq(uint8 add)
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
