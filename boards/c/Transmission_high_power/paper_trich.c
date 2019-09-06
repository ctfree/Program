/*
 * paper_trich.c
 *
 *  Created on: 14 juin 2018
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

//#define SOURCE

#define RELAY

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

//#define t_seuil 5  // to edit

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





/*************************************************************************
 //receiver thread*/



static PT_THREAD (recv_thread(void*args))
        {

    uint8 r,misc, length, adress, type, retry=0 ,  buf[PKT_SIZE+2], time;

    uint16 time1, time2;

    float t_duration, time_opt=0.7;

    unsigned short adress_received;
    uint8 wub[WUB_LENGTH] ;

    PT_BEGIN (&_recv_thread_pt);

    for ( ;; ){


debut:


        cc112x_sleep();
        WAIT_EVENT (&_recv_thread_pt);

        // wur was received so we send CTS


      // cc112x_set_cca(CCA_RSSI);

        cc112x_set_cca(CCA_NO);

        misc=CTS;
        cc112x_data_mode();

        // send a cts at 12.5 dbm

        // Output power to the 12.5 dBm
           // cc112x_set_output_power(0x3C);

        cc112x_set_output_power(0x37);//10dbm

       r= cc112x_tx_pkt (&misc, CTS_SIZE, ED_ADDRESS);


       if (r!=TXPKT_SUCCESS){

            uart_puts("CTS was not sent\n\r");

            ENABLE_WURX_IT;
            goto debut;
        }



       // If the RX fifo is not empty, the RX FIFO consummer thread is scheduled
              if (!FIFO_IS_EMPTY(rx_fifo_first, rx_fifo_last)) {
                  schedule_thread(_rx_fifo_cons, true);

              }

end:
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

   /* if (rx_fifo_cons == NULL) {
    PT_INIT(&_sender_thread_pt, sender_thread, NULL);
    register_thread(&_sender_thread_pt, true);
    set_periodic_timer(&_sender_thread_pt,  RCV_WAKEUP_INTERVAL);
    // Set the interrupt handler for WuRx interrupt
   // io_interrupts_add_func_handler(2, 5, LOW_TO_HIGH, sender_thread);


    //cc112x_set_ctn_thr(&_sender_thread_pt);
    }*/
    // Initializing the sender thread only of a receving thread is specified

        PT_INIT(&_recv_thread_pt, recv_thread, NULL);
        register_thread(&_recv_thread_pt, true);
        // Enabling the WuRx interrupt
         // ENABLE_WURX_IT;

          ENABLE_WURX_IT;
          // Initializing the WuRx
         wurx_init(&_recv_thread_pt);








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

#elif  defined RELAY


    ricer_init (&sink_thread_pt);
    start_threads ();

#endif
}



