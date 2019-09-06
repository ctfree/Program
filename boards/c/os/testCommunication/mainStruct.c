/*
 * mainStruct.c
 *
 *  Created on: 24 avr. 2018
 *      Author: djidi
 */

#include <network/mac/pw-mac/pw-mac.h>
#include <drivers/radio/cc112x.h>
#include <drivers/wurx/wurx.h>
#include <tools/timer/timer.h>
#include <stddef.h>
#include <string.h>
#include <config.h>
#include <stdlib.h>
#include <stdbool.h>
#include "stdint.h"
#include <drivers/serial/spi/spi.h>
#include <drivers/platform.h>
#include <pt/pt.h>
#include <sched/sched.h>
#include <tools/misc.h>

#include <drivers/serial/uart/uart.h>
#include <pm/pm.h>






#define SOURCE  0
//#define SINK  1u


#define SINK_MAC_ADDR   0x55u
// FIFO variables: shared with the app threads
struct fifo_pkt_t tx_fifo[TX_FIFO_SIZE];
struct fifo_pkt_t rx_fifo[RX_FIFO_SIZE];
uint8 tx_fifo_first = 0u;
uint8 tx_fifo_last = 0u;
uint8 rx_fifo_first = 0u;
uint8 rx_fifo_last = 0u;

#define DATA        0b10000000u
#define PKT_SIZE 6
float pkt[PKT_SIZE]={1,2,3,4,5,6};

/*****************************************not sur*****************************/
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
 /**********************************************************************************************************/








void main (){
float *data=pkt;
    int r;
     msp2zigv_init();
     WDT_DISABLE;
   //  set_voltage(1);
    // LPM3;
     _EINT();
     timer_init();
     uart_init();
     spi_init();
     //uart_puts("Sink is ready.\n\r");
     // uart_flush();

     // Initalizes the CC1120
     cc112x_init(2u);

     // Enable the device address filtering and set the device address
     cc112x_set_addr_check(ADDR_CHK_B1, SELF_MAC_ADDRESS);


#ifdef SOURCE
     uint8 dst_address =  SINK_MAC_ADDR ;

     for (;;){

               // cc112x_data_mode ();

         tx_fifo[tx_fifo_first].address = dst_address;
                 tx_fifo[tx_fifo_first].buffer[0] = DATA;
                 tx_fifo[tx_fifo_first].buffer[1] = get_incr_tx_seq(dst_address);
                 memcpy(&(tx_fifo[tx_fifo_first].buffer[2]), data, PKT_SIZE);
                // FIFO_INCR_PTR(tx_fifo_last, TX_FIFO_SIZE);

                 r = cc112x_tx_pkt(tx_fifo[tx_fifo_first].buffer, PKT_SIZE+2, tx_fifo[tx_fifo_first].address);
                 if (r != TXPKT_SUCCESS) {
                                        // Error when sending the data frame
                                        uart_puts("Data was not sent\n\r");
                                        break;
                                    }

     }

#elif defined SINK


#endif
}


