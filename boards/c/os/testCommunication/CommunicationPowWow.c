/*
 * mainTest2.c
 *
 *  Created on: 26 avr. 2018
 *      Author: djidi
 *
 *
 *      communication between 2 powWow
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




#define SOURCE
//#define SINK

//#define SINK_MAC_ADDR   0x55u

// Frames Types (2 bits)
#define ACK         0b01000000u
#define DATA        0b10000000u


// Frame length
//#define ACK_SIZE    1u

// ************************************************************
// FIFO variables: shared with the app threads
struct fifo_pkt_t tx_fifo[TX_FIFO_SIZE];
struct fifo_pkt_t rx_fifo[RX_FIFO_SIZE];
uint8 tx_fifo_first = 0u;
uint8 tx_fifo_last = 0u;
uint8 rx_fifo_first = 0u;
uint8 rx_fifo_last = 0u;

// Thread to schedule when the RX FIFO is not empty
static struct pt *_rx_fifo_cons;

// Sending thread
static struct pt _sender_thread_pt;

// Receiving thread
static struct pt _recv_thread_pt;

// Is the sending thread scheduled
static bool _is_sending_sched = false;



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




/*
 * Sender thread.
 *
 * This thread is responsible for pulling packet from the TX FIFO and sending them.
 */
static PT_THREAD(sender_thread(void *args))
{
    uint8 r;
 //    buf[PKT_SIZE+2], length, address, type, retry = 0u;
    int32 pred_error;

    PT_BEGIN(&_sender_thread_pt);

   for ( ;; ) {

       // cc112x_sleep();
       // WAIT_EVENT(&_sender_thread_pt);
     /* if (FIFO_IS_EMPTY(tx_fifo_first, tx_fifo_last)) {
                continue;
            }*/

        //not sur for adding this

     //  tx_fifo_first= tx_fifo_last;

      for ( ;; ) {
                    // Sending the data
            cc112x_set_cca( CCA_RSSI);

                      tx_fifo[tx_fifo_first].buffer[0] = DATA;    // We are already sync not need
                    //cc112x_data_mode();
                   r = cc112x_tx_pkt(tx_fifo[tx_fifo_first].buffer, PKT_SIZE+2, tx_fifo[tx_fifo_first].address);
                    if (r == TXPKT_SUCCESS) {
                        // Error when sending the data frame
                        uart_puts("Data was sent\n\r");
                        break;
                    }


                    else if (r==TXPKT_FIFO_ERR){
                        uart_puts("error in the fifo\n\r");
                                            break;
                                        }

                    else if (r==TXPKT_WRONG_MODE){
                        uart_puts("you are in the wrong mode\n\r");
                                  break;
                                              }

                    else if (r==TXPKT_UNEXCP ){

                        uart_puts("you are in inexpecting \n\r");
                                  break;
                    }

                    else if (r==TXPKT_CCA_ERR){

                        uart_puts("channel is not free \n\r");
                                                         break;
                    }


                    else {

                        uart_puts("Data was not sent\n\r");

                        break;
                    }

                    // If we are here, everything went fine.
                          //  FIFO_INCR_PTR(tx_fifo_first, TX_FIFO_SIZE);
        }
    }

        PT_END(&_sender_thread_pt);

}


/*********************************************************receiver thread************************************************/

static PT_THREAD(recv_thread(void *args))
{
    uint8 r, misc, length, address, type, seq, exc_seq, retry = 0;

    PT_BEGIN(&_recv_thread_pt);

    for ( ;; )
    {
      //  cc112x_sleep();



      // WAIT_EVENT(&_recv_thread_pt);

        cc112x_set_rx_timeout(RX_TIMEOUT);

        for ( ;; ) {
                // Receiving the data frame
                cc112x_data_mode();
                r = cc112x_rx_pkt(rx_fifo[rx_fifo_last].buffer, &length, &address, true);
                if (r == RXPKT_CRC_ERR) {
                    // CRC error means collision usually.
                    uart_puts("Data was not received\n\r");
                }

                else if (r == RXPKT_SUCCESS) {
                    uart_puts("Data was received\n\r");
                                type = rx_fifo[rx_fifo_last].buffer[0];
                                if ((type != DATA)) {
                                    // We received something unexpected
                                    uart_puts("Data was received but corrupted\n\r");
                                }
                }
                                else {
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

/*****************************************************initialiser le mac protocole**************************************************************/


    /* Initialize the MAC protocol.
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

       // initialiser uart
       uart_init();

       // Initalizes the CC1120
      // cc112x_init(2u);

       // Enable the device address filtering and set the device address
       cc112x_set_addr_check(ADDR_CHK_B1, SELF_MAC_ADDRESS);

       // Putting radio chip in sleep state
     //  cc112x_sleep();

       // Initializing the sender thread
       if (rx_fifo_cons == NULL){
       PT_INIT(&_sender_thread_pt, sender_thread, NULL);
       register_thread(&_sender_thread_pt, true);
       }
       // Initializing the sender thread only if a receving thread is specified
       else{
           PT_INIT(&_recv_thread_pt, recv_thread, NULL);
           register_thread(&_recv_thread_pt, true);

       }
   }



/****************************************************************send a packet *******************************************/

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


       if (!_is_sending_sched) {
               schedule_thread(&_sender_thread_pt,true);
           }

       return SWM_TX_SUCCESS;

   }


////////////////************************************************************sink ou source******************************************************/
//#define PKT_SIZE 6

uint8 pkt[PKT_SIZE];


#ifdef SINK
// Protothread that handles reception of packets

struct pt sink_thread_pt ;

static PT_THREAD(sink_thread(void *args))
{
    uint8 addr;

    PT_BEGIN(&sink_thread_pt);

    for ( ;; )
    {
       WAIT_EVENT(&sink_thread_pt);
       /* while (!FIFO_IS_EMPTY(rx_fifo_first, rx_fifo_last)) {
            // Received a data
            // Sending the address
            addr = *(uint8*)&(rx_fifo[rx_fifo_first].address);
            uart_send_uint((unsigned int)addr, 10u);
            uart_putchar(' ');
            memcpy(pkt, rx_fifo[rx_fifo_first].buffer + 2, PKT_SIZE);


            FIFO_INCR_PTR(rx_fifo_first, RX_FIFO_SIZE);*/
       // }

    }


    PT_END(&sink_thread_pt);
}


/**************************************************source**************************************************************/

#elif defined SOURCE

// Protothread that sends data
static struct pt source_thread_pt;
static PT_THREAD(source_thread(void *args))
{
    PT_BEGIN(&source_thread_pt);

    for ( ;; )
        {
            WAIT_EVENT(&source_thread_pt);

            pwmac_send(pkt, SINK_ADDRESS);



        }

    PT_END(&source_thread_pt);
}



#endif  // SOURCE







void main (){


    int r;
      msp2zigv_init();
      WDT_DISABLE;
    //  set_voltage(1);
     // LPM3;
      _EINT();
      timer_init();
    //  uart_init();
      spi_init();
      //uart_puts("Sink is ready.\n\r");
      // uart_flush();

      // Initalizes the CC1120
      cc112x_init(2u);




#ifdef SINK
      // Initializing the sink thread
             PT_INIT(&sink_thread_pt, sink_thread, NULL);
             register_thread(&sink_thread_pt,true);
             pwmac_init(&sink_thread_pt);

             uart_puts("Sink ready;");


             start_threads();



#elif defined SOURCE





        // pm_init();

            pwmac_init(NULL);

            // Initializing the source thread
            PT_INIT(&source_thread_pt, source_thread, NULL);
            register_thread(&source_thread_pt,true);

            start_threads();
#endif
    //






}


