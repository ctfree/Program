/*
 * Implementation of the PW-MAC protocol.
 *
 * ****************** !! NOTE: THE CC112X radio chip driver is used.
 */

#ifdef PWMAC

#include <network/mac/pw-mac/pw-mac.h>
#include <drivers/radio/cc112x.h>
#include <drivers/wurx/wurx.h>
#include <tools/timer/timer.h>
#include <stddef.h>
#include <string.h>
#include <config.h>
#include <stdlib.h>
#include <stdbool.h>

// Frames Types (2 bits)
#define BCN			0b00000000u
#define ACK			0b01000000u
#define DATA		0b10000000u
#define NACK		0b11000000u	// Failure ACK
#define DATAS		0b00100000u	// Data with sync request
#define ACKS		0b01100000u // ACK with sync information

/*
 * Convert the time unit used by CC112X RX timer to slow rate MCU timer
 */
#define TIME_CONV_CC112X_TO_SLOW(x) (x / 400)

struct nack_frame
{
	uint8 	type;	// Type
	uint16	bw;		// Backoff window
};

struct acks_frame
{
	uint8	misc;			// Type + SEQ
	uint32	current_time;	// Sink time
};

// Frame length
#define BCN_SIZE	1u
#define ACK_SIZE	1u
#define NACK_SIZE	sizeof(struct nack_frame)
#define ACKS_SIZE	sizeof(struct acks_frame)

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

// Has the node synchronization informations about the sink
static bool _is_sync = false;

// Last update sink time
static uint32 _last_update_time = 0u;

// Time difference between us and the sink
static int32 _time_diff;

// Next wake up time of the sink
static uint32 _sink_next_wup;

// Need resynchronization
static bool _need_resync = false;

// Is sending scheduled ?
static bool _sending_sched = false;

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
 * Set a timer to the next time the node should wake up to receive a becon from the sink.
 * Returns true if the node should go to sleep, false otherwhise.
 * This is the PW-MAC algorithm modified for periodic wake up.
 */
static void _set_sending_timer(void)
{
	_sending_sched = true;

	// If we are here, the TX FIFO is not empty. Thus we should set a timer to wake up
	// the node just before the next time the sink will wake up
	// We use the one shot timer here.
	uint32 sink_current_time = get_localtime() - _time_diff;
	int32 drift = DRIFT*(sink_current_time - _last_update_time);
	if (_sink_next_wup > sink_current_time) {
		uint16 timer_val = _sink_next_wup - sink_current_time;
		set_one_shot_timer_sleep(timer_val, &_sender_thread_pt);
		return;
	}
	while (_sink_next_wup < sink_current_time + A + drift) {
		_sink_next_wup += RCV_WAKEUP_INTERVAL;
	}
	if (_sink_next_wup > sink_current_time + A + drift) {
		uint16 timer_val = _sink_next_wup - (sink_current_time + A + drift);
		set_one_shot_timer_sleep(timer_val, &_sender_thread_pt);
		return;
	}
	schedule_thread(&_sender_thread_pt, true);
}

/*
 * Sender thread.
 *
 * This thread is responsible for pulling packet from the TX FIFO and sending them.
 */
static PT_THREAD(sender_thread(void *args))
{
	int r;
	uint8 buf[PKT_SIZE+2], length, address, type, retry = 0u;
	int32 pred_error;

	PT_BEGIN(&_sender_thread_pt);

	for ( ;; ) {

		cc112x_sleep();
		WAIT_EVENT(&_sender_thread_pt);

		// Time to send a packet. We will wake up at the right time.
		_set_sending_timer();

		WAIT_EVENT(&_sender_thread_pt);

		// Wait for the beacon
		do {
			r = cc112x_rx_pkt(buf, &length, &address, false);
			type = buf[0];
		} while ((r != RXPKT_SUCCESS) && (type != BCN));
		// Compute the prediction error
		pred_error = _sink_next_wup - (get_localtime() - _time_diff);
		// Do we need resynchronization ?
		if (pred_error < 0) {
			pred_error = -pred_error;
		}
		if (_is_sync && pred_error > A) {
			_need_resync = true;
		}
		// Enabling the CCA
		cc112x_set_cca(CCA_RSSI);
		for ( ;; ) {
			// Sending the data
			if (_is_sync && !_need_resync) {
				tx_fifo[tx_fifo_first].buffer[0] = DATA;	// We are already sync
			} else {
				tx_fifo[tx_fifo_first].buffer[0] = DATAS;	// We need to synch
			}
			r = cc112x_tx_pkt(tx_fifo[tx_fifo_first].buffer, PKT_SIZE+2, tx_fifo[tx_fifo_first].address);
			if (r != TXPKT_SUCCESS) {
				// Error when sending the data frame
				break;
			}
			// Set RX timer to default value
			cc112x_set_rx_timeout(RX_TIMEOUT);
			// Waiting for the ACK
			r = cc112x_rx_pkt(buf, &length, &address, true);
			if (r != RXPKT_SUCCESS) {
				// Error when receiving the ACK
				break;
			}
			type = buf[0];
			if (type == NACK) {
				// Transmission failure. The sink asks us to transmit again after a backoff
				if (retry == MAX_RETRIALS) {
					// We already tried to many times. Dropping this packet and trying the next one
					FIFO_INCR_PTR(tx_fifo_first, TX_FIFO_SIZE);
					break;
				} else {
					struct nack_frame *nack = (struct nack_frame*)buf;
					uint16 backoff_time = rand() & (nack->bw-1u);
					retry++;
					if (backoff_time > 0) {
						set_one_shot_timer(TIME_CONV_CC112X_TO_SLOW(backoff_time));
						while (!has_one_shot_timer_expired());
					}
					continue;
				}
			} else if (type == ACKS) {
				// Receive synch info.
				struct acks_frame *acks = (struct acks_frame*)buf;
				_time_diff = get_localtime() - acks->current_time;
				_last_update_time = acks->current_time;
				_is_sync = true;
				_need_resync = false;
			} else if (type != ACK) {
				// Receive unexpected frame
				break;
			}
			// If we are here, everything went fine ! We can send the next packet if any
			FIFO_INCR_PTR(tx_fifo_first, TX_FIFO_SIZE);
			if (FIFO_IS_EMPTY(tx_fifo_first, tx_fifo_last)) {
				_sending_sched = false;
				break;
			}
		}

		// If the TX fifo is not empty, then something went wrong.
		// We schedule the thread for the next wake up of the sink.
		if (!FIFO_IS_EMPTY(tx_fifo_first, tx_fifo_last)) {
			uint16 max_backoff = EXP_BACKOFF_BASE;
			uint16 backoff = rand() & (max_backoff-1u);
			set_one_shot_timer_sleep(backoff, &_sender_thread_pt);
		} else {
			_sending_sched = false;
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
	uint8 r, misc, length, address, type, seq, exc_seq, retry = 0;

	PT_BEGIN(&_recv_thread_pt);

	for ( ;; )
	{
		cc112x_sleep();
		WAIT_EVENT(&_recv_thread_pt);

		// Time to send a beacon !

		// Sending the beacon
		// Enabling CCA
		cc112x_set_cca(CCA_RSSI);
		misc = BCN;	// No seq for BCN
		//P3OUT |= BIT0;	//TODO
		r = cc112x_tx_pkt(&misc, BCN_SIZE, BROADCAST_ADDRESS);
		//P3OUT &= ~BIT0;	//TODO
		if (r != TXPKT_SUCCESS) {
			// Error while sending the beacon
			continue;
		}
		// Disabling CCA
		cc112x_set_cca(CCA_NO);
		// Set RX timer to default value
		cc112x_set_rx_timeout(RX_TIMEOUT);
		for ( ;; ) {
			// Receiving the data frame
			r = cc112x_rx_pkt(rx_fifo[rx_fifo_last].buffer, &length, &address, true);
			if (r == RXPKT_CRC_ERR) {
				// CRC error means collision usually. Thus, we transmit an NACK frame to ask the nodes
				// to retry after a backoff.
				if (retry == MAX_RETRIALS) {
					break;
				}
				uint16 backoff = EXP_BACKOFF_BASE << retry;
				struct nack_frame nack = {NACK, backoff};
				// Sending NACK
				cc112x_tx_pkt((uint8*)&nack, NACK_SIZE, BROADCAST_ADDRESS);
				// Trying again to receive data with timeout set to the exp backoff
				cc112x_set_rx_timeout(backoff);
				retry++;
				continue;
			} else if (r == RXPKT_SUCCESS) {
				type = rx_fifo[rx_fifo_last].buffer[0];
				if ((type != DATA) && (type != DATAS)) {
					// We received something unexpected
					if (retry == 0) {
						break;
					} else {
						continue;
					}
				}
				// Check the sequence number
				seq = rx_fifo[rx_fifo_last].buffer[1];
				exc_seq = get_next_rx_seq(address);
				if (seq != exc_seq - 1) {
					// Not received yet
					set_rx_seq(address, seq);
					rx_fifo[rx_fifo_last].address = address;
					FIFO_INCR_PTR(rx_fifo_last, RX_FIFO_SIZE);
				}
				if (type == DATA) {
					// If we are here, the dataframe was correctly received
					misc = ACK;
					// Sending ACK
					cc112x_tx_pkt(&misc, ACK_SIZE, address);
				} else if (type == DATAS) {
					// If we are here, the dataframe was correctly received and a syncrhonization request was
					// sent. We answer with an ACKS frame including the localtime
					struct acks_frame acks;
					acks.misc = ACKS;
					acks.current_time = get_localtime();
					// Sending ACKS
					cc112x_tx_pkt((uint8*)&acks, ACKS_SIZE, address);
				}
				// At the end of the ACK transmission, we listen again if another node has data to transmit
			} else {
				break;
			}
		}

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
void pwmac_init(struct pt *rx_fifo_cons)
{
	_rx_fifo_cons = rx_fifo_cons;

	// Initalizes the CC1120
	cc112x_init(2u);

	// Enable the device address filtering and set the device address
	cc112x_set_addr_check(ADDR_CHK_B1, SELF_MAC_ADDRESS);

	// Putting radio chip in sleep state
	cc112x_sleep();

	// Initializing the sender thread
	PT_INIT(&_sender_thread_pt, sender_thread, NULL);
	register_thread(&_sender_thread_pt, true);

	// Initializing the sender thread only of a receving thread is specified
	if (rx_fifo_cons != NULL) {
		PT_INIT(&_recv_thread_pt, recv_thread, NULL);
		register_thread(&_recv_thread_pt, true);
		set_periodic_timer(&_recv_thread_pt, RCV_WAKEUP_INTERVAL);
	}
}

/*
 * Send a packet.
 *
 * - data: pointer to the data to send.
 * - length: length of the data payload.
 * - dst_address: address of the receiver. Must be a 7 bits value.
 */
int pwmac_send(uint8 *data, uint8 dst_address)
{

	// Checking that the TX FIFO is not full
	if (!FIFO_IS_FULL(tx_fifo_first, tx_fifo_last, TX_FIFO_SIZE)) {
		// Adding the data to the TX FIFO
		tx_fifo[tx_fifo_last].address = dst_address;
		tx_fifo[tx_fifo_last].buffer[1] = get_incr_tx_seq(dst_address);
		memcpy(&(tx_fifo[tx_fifo_last].buffer[2]), data, PKT_SIZE);
		FIFO_INCR_PTR(tx_fifo_last, TX_FIFO_SIZE);
	}

	if (!_is_sync) {
		schedule_thread(&_sender_thread_pt, true);
	} else if (!_sending_sched) {
		//_set_sending_timer();
		schedule_thread(&_sender_thread_pt, true);
	}

	return SWM_TX_SUCCESS;
}

/* For debug
 */
uint8 pwmac_get_rx_seq(uint8 add)
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

uint8 pwmac_get_tx_seq(uint8 add)
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
