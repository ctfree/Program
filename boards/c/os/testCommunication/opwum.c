/*
 * opwum.c
 *
 *  Created on: 7 juin 2018
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
#include <time.h>

#define SOURCE
//#define SINK

// Frames Types (2 bits)
#define BCN         0b00000000u
#define ACK         0b01000000u
#define DATA        0b10000000u
#define RTS         0x00u
#define ATS         0x01u
#define CTS         0x02u


// Frame length
#define BCN_SIZE    1u
#define ACK_SIZE    1u
#define CTS_SIZE    1u
#define ATS_SIZE    1u

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


/*
 * ***************************************function to recupeer adress from pin 2.7
 */
unsigned short receive_adress ()
{
    unsigned int out;

    unsigned char recv_vector[16];
    int rec_i;

    while (WURX_DATA_PIN==1); //wait first descent slope

    for ( rec_i=1; rec_i<16; rec_i++){


        recv_vector[rec_i]= WURX_DATA_PIN;
        // delay de 1 ms

    }

    recv_vector [0]=1;
    out=0;
    for(rec_i=15;rec_i>=0;rec_i--)
        out|=(recv_vector[15-rec_i])<<(rec_i);

    return out;


}



/************************************************************************
 //sender thread*/

/************************************************************************
 //sender thread*/


static PT_THREAD (sender_thread(void *args))

  {


    uint8 r,buf[PKT_SIZE+2], length, adress, type, retry=0u,debug, backoff;

    uint8 pkt[PKT_SIZE];
    uint8 seq,i;

    uint8 wub[2] = {0xA5,0x00};
    backoff=5;

    PT_BEGIN (&_sender_thread_pt);

    for ( ;; ){



        cc112x_sleep();
        WAIT_EVENT(&_sender_thread_pt);


debut:
        //cc112x_sleep();
        //backoff
        //set_one_shot_timer_sleep(backoff, &_sender_thread_pt);

         //cc112x_set_cca(CCA_RSSI);
        cc112x_set_cca(CCA_NO);

       // send wake_up signal RTS

retry:
        wub[1]=RTS;
        cc112x_wub_mode();

        r = cc112x_tx_wub(wub);

        if (r==TXPKT_CCA_ERR){
            uart_puts (" channel not free\n");
            goto debut;
        }

        // receive CTS

         cc112x_data_mode();

         cc112x_set_rx_timeout(RX_TIMEOUT);

         r=cc112x_rx_pkt(buf, &length, &adress, true);

         if ((r != RXPKT_SUCCESS )|| (buf[0]!= CTS)){

             goto debut;
         }

         //send ATS

         wub[1]=ATS;

         cc112x_wub_mode();
         r = cc112x_tx_wub(wub);

         if (r==TXPKT_CCA_ERR){
                  goto debut;
              }
         //laisser un petit time le temps que le receiver se reveille a nouveau
        // set_one_shot_timer_sleep(5u, &_sender_thread_pt); //10 ms


         //send data
          cc112x_data_mode();

          //cc112x_set_output_power(0x3F);

          cc112x_set_output_power(0x0F);
          tx_fifo[tx_fifo_first].buffer[0] = DATA;    // We are already sync not need


        //  uart_printf(" l'adresse est  : %u\n ",tx_fifo[tx_fifo_first].address);

           r = cc112x_tx_pkt(tx_fifo[tx_fifo_first].buffer, PKT_SIZE+2, tx_fifo[tx_fifo_first].address);

            if (r != TXPKT_SUCCESS){
                goto debut;
            }


           // receive ack

            cc112x_set_rx_timeout(RX_TIMEOUT);

            r=cc112x_rx_pkt(buf, &length, &adress, true);

            type =buf [0];


            if ((r == RXPKT_SUCCESS) && (type == ACK) ) {

                uart_puts("ACK was received\n\r");
                               }

            else
                uart_puts("ACK was not received\n\r");

            //ajouter un goto debut



        }


    PT_END(&_sender_thread_pt);


    }


/*************************************************************************
 //receiver thread*/



static PT_THREAD (recv_thread(void*args))
        {

    uint8 r,misc, length, adress, type, retry=0;

    unsigned short adress_received;

    PT_BEGIN (&_recv_thread_pt);

    for ( ;; ){

debut:
        cc112x_sleep();
        WAIT_EVENT (&_recv_thread_pt);

        //RTS wur received so we send CTS


      // cc112x_set_cca(CCA_RSSI);

        cc112x_set_cca(CCA_NO);
retry:
        misc=CTS;

       r= cc112x_tx_pkt (&misc, CTS_SIZE, BROADCAST_ADDRESS);


       if (r!=TXPKT_SUCCESS){

            uart_puts("CTS was not sent\n\r");

            ENABLE_WURX_IT;
            goto debut;
        }



       //wait an interruption
       // Enabling WuRx IT
         ENABLE_WURX_IT;
         WAIT_EVENT (&_recv_thread_pt);


        // mettre par defaut le rx (40 ms)
            // Set RX timer to default value
       cc112x_set_rx_timeout(RX_TIMEOUT);

       cc112x_data_mode();

       // time to receive data
       r = cc112x_rx_pkt(rx_fifo[rx_fifo_last].buffer, &length, &adress, true);
       type = rx_fifo[rx_fifo_last].buffer[0];


       if ((r != RXPKT_SUCCESS) || (type!=DATA)) {
           // revenir au debut
           // Enabling WuRx IT
             ENABLE_WURX_IT;

            goto debut;

       }



    // data was received so we send ACK

         misc=ACK ;

         r= cc112x_tx_pkt (&misc, ACK_SIZE, adress);

        if (r!=TXPKT_SUCCESS){

            uart_puts("ACK was not sent\n\r");

        }

         else {
              uart_puts("ACK was sent\n\r");
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














