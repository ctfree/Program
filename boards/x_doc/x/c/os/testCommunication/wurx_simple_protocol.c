/*
 * wurx_simple_protocol.c
 *
 *  Created on: 6 juin 2018
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
#include <pt/pt.h>
#include <tools/misc.h>
#include <drivers/serial/uart/uart.h>
#include <sched/sched.h>
#include <drivers/serial/spi/spi.h>
#include <drivers/platform.h>
#include <tools/io_interrupts/io_interrupts.h>

#define SOURCE
//#define SINK

// Frames Types (2 bits)
#define BCN         0b00000000u
#define ACK         0b01000000u
#define DATA        0b10000000u
#define NACK        0b11000000u // Failure ACK
#define DATAS       0b00100000u // Data with sync request
#define ACKS        0b01100000u // ACK with sync information


// Frame length
#define BCN_SIZE    1u
#define ACK_SIZE    1u


/***********************************************************************
 Fifo variable: shared with the ap threads*/

struct fifo_pkt_t tx_fifo[TX_FIFO_SIZE];
struct fifo_pkt_t rx_fifo[RX_FIFO_SIZE];

uint8 tx_fifo_first =0u;
uint8 tx_fifo_last=0u;
uint8 rx_fifo_first=0u;
uint8 rx_fifo_last=0u;

//************************************************************************

//priviate variables
//thread to schedule when the RX FIFO is not empty
static struct pt *_rx_fifo_cons;


//sender thread

static struct pt _sender_thread_pt;


//receiver thread

static struct pt _recv_thread_pt;

/************************************************************************
 //sender thread*/

/************************************************************************
 //sender thread*/


static PT_THREAD (sender_thread(void *args))

  {


    uint8 r,buf[PKT_SIZE+2], length, adress, type, retry=0u,debug;

    uint8 pkt[PKT_SIZE];
    uint8 seq,i;

    uint8 wub[] = {0xA5,0xA5};

    PT_BEGIN (&_sender_thread_pt);

    for ( ;; ){



        WAIT_EVENT(&_sender_thread_pt);

       // send wake_up signal

retry:
        cc112x_wub_mode();
              // cca should be enable but i disable it because of a problem in the lab
             // cc112x_set_cca(CCA_RSSI);
        cc112x_set_cca(CCA_NO);

              //misc=BCN; //No seq for BCN

             //r= cc112x_tx_pkt (&misc, BCN_SIZE, BROADCAST_ADDRESS);
        r = cc112x_tx_wub(wub);


        // receive ack

         cc112x_data_mode();

         cc112x_set_rx_timeout(RX_TIMEOUT);

         r=cc112x_rx_pkt(buf, &length, &adress, true);

         if (r != RXPKT_SUCCESS){

             goto retry;
         }


         //send data

           cc112x_set_cca(CCA_NO);

           tx_fifo[tx_fifo_first].buffer[0] = DATA;    // We are already sync not need


        //  uart_printf(" l'adresse est  : %u\n ",tx_fifo[tx_fifo_first].address);

           r = cc112x_tx_pkt(tx_fifo[tx_fifo_first].buffer, PKT_SIZE+2, tx_fifo[tx_fifo_first].address);

             if (r == TXPKT_SUCCESS) {

             // uart_puts("Data was sent\n\r");

              // receive ack

              cc112x_set_rx_timeout(RX_TIMEOUT);

              r=cc112x_rx_pkt(buf, &length, &adress, true);

              type =buf [0];


                   if ((r == RXPKT_SUCCESS) && (type == ACK) ) {

                      uart_puts("ACK was received\n\r");
                               }

                   else
                     uart_puts("ACK was not received\n\r");


                         }


             else {

             uart_puts("Data was not sent\n\r");
                    }




        }


    PT_END(&_sender_thread_pt);




    }





/*************************************************************************
 //receiver thread*/



static PT_THREAD (recv_thread(void*args))
        {

    uint8 r,misc, length, adress, type, retry=0;



    PT_BEGIN (&_recv_thread_pt);

    for ( ;; ){


        cc112x_sleep();
        WAIT_EVENT (&_recv_thread_pt);

        //wur received so we send ACK

        // cca should be enable but i disable it because of a problem in the lab
       // cc112x_set_cca(CCA_RSSI);
        cc112x_set_cca(CCA_NO);
retry:
        misc=ACK;

       r= cc112x_tx_pkt (&misc, ACK_SIZE, BROADCAST_ADDRESS);


       if (r!=TXPKT_SUCCESS){

            uart_puts("ACK_wur was not sent\n\r");
           goto retry;
        }



          //  uart_puts("ACK_wur was sent\n\r");


        // mettre par defaut le rx (40 ms)
            // Set RX timer to default value
           cc112x_set_rx_timeout(RX_TIMEOUT);

           //data mode
        //   cc112x_data_mode();

       // time to receive data
       r = cc112x_rx_pkt(rx_fifo[rx_fifo_last].buffer, &length, &adress, true);


                 if (r == RXPKT_SUCCESS) {

                  //uart_puts("Data was received\n\r");
                  type = rx_fifo[rx_fifo_last].buffer[0];

                            if ((type != DATA)) {
                             // We received something unexpected
                           //  uart_puts("Data was received but corrupted\n\r");
                                       }


                             else {
                                // data was received so we send ACK

                                misc=ACK ; //No seq for BCN

                                r= cc112x_tx_pkt (&misc, ACK_SIZE, adress);

                                       if (r!=TXPKT_SUCCESS){

                                        uart_puts("ACK was not sent\n\r");
                                           //continue;
                                            }

                                         else {
                                                uart_puts("ACK was sent\n\r");
                                           }
                            }

                       }


                 else
                 {
                     uart_puts("Data was not received\n\r");

                     // send not ack


                 }





       // If the RX fifo is not empty, the RX FIFO consummer thread is scheduled
              if (!FIFO_IS_EMPTY(rx_fifo_first, rx_fifo_last)) {
                  schedule_thread(_rx_fifo_cons, true);

              }

              // Enabling WuRx IT
               ENABLE_WURX_IT;

    }


    PT_END(&_recv_thread_pt);

        }


/***************************************************************************************************
 *Initialize the MAC protocol
 */


void ricer_init(struct pt *rx_fifo_cons)
{
    _rx_fifo_cons = rx_fifo_cons;

    // initialiser uart

    uart_init();

    // Initalizes the CC1120
    cc112x_init(2u);

    // Enable the device address filtering and set the device address
    cc112x_set_addr_check(ADDR_CHK_B1, SELF_MAC_ADDRESS);

    // Putting radio chip in sleep state
    cc112x_sleep();

    // Initializing the sender thread

    if (rx_fifo_cons == NULL) {
    PT_INIT(&_sender_thread_pt, sender_thread, NULL);
    register_thread(&_sender_thread_pt, true);
    set_periodic_timer(&_sender_thread_pt,  RCV_WAKEUP_INTERVAL);
    // Set the interrupt handler for WuRx interrupt
   // io_interrupts_add_func_handler(2, 5, LOW_TO_HIGH, sender_thread);


    //cc112x_set_ctn_thr(&_sender_thread_pt);
    }
    // Initializing the sender thread only of a receving thread is specified
    else {
        PT_INIT(&_recv_thread_pt, recv_thread, NULL);
        register_thread(&_recv_thread_pt, true);
        // Enabling the WuRx interrupt
         // ENABLE_WURX_IT;

          ENABLE_WURX_IT;
          // Initializing the WuRx
         wurx_init(&_recv_thread_pt);


    }





}


/*************************************************************************************************
 * main
 */
static struct pt sink_thread_pt;
void main (void){







    msp2zigv_init();



    WDT_DISABLE;
    timer_init();
    _EINT();
    spi_init();
  //  cc112x_init(2u);
#ifdef SOURCE

    ricer_init (NULL);
    start_threads();

#elif  defined SINK


    ricer_init (&sink_thread_pt);
    start_threads ();

#endif
}









