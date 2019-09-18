/*
 * main.c
 *
 *  Created on: 20 avr. 2018
 *      Author: djidi
 */



/*
 * Test app to evaluate fuzzyman in a one-hop network.
 * There is NO real network stack. Packets are sent directly without
 *  even a CCA.
 */

#include <drivers/platform.h>
#include <tools/timer/timer.h>
#include <pt/pt.h>
#include <sched/sched.h>
#include <tools/misc.h>
#include <stddef.h>
#include <drivers/serial/spi/spi.h>

#include <config.h>
#include <network/mac/csma-ca/csma-ca.h>
#include <drivers/radio/cc112x.h>
#include <string.h>
#include <stdlib.h>
#include <stdbool.h>
#include "stdint.h"
#include <drivers/wurx/wurx.h>
/*
 * Packet payload size
 */
#define PACKET_SIZE 6




/*
 * Interval between the sending of two packets in sec
 */
#define PERIOD  143

//#define SOURCE  0
#define SINK  1u

#define SINK_MAC_ADDR   0x55u


/*
 * Frame buffer
 */
float packet[PACKET_SIZE];

/*
 * Send a packet periodically
 */
//static struct pt app_thread_pt;
/*static PT_THREAD(app_thread(void *args))
{
    PT_BEGIN(&app_thread_pt);

    for ( ;; ) {
        radio_wakeup();
        radio_send(packet, PACKET_SIZE*sizeof(unsigned int), false);
        radio_powerdown();
        SET_TIMER_SLEEP_10MS(&app_thread_pt, PERIOD);
    }

    PT_END(&app_thread_pt);
}*/

int main(void)
{
    uint8 buf[PKT_SIZE+2], length, address, type, max_backoff, backoff;
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

    // Initializing random number generator
      //  srand(SELF_MAC_ADDRESS);


        WDTCTL = WDTPW | WDTHOLD;       // stop watchdog timer
            P1DIR |= 0x01;                  // configure P1.0 as output

            volatile unsigned int i;        // volatile to prevent optimization


#ifdef SOURCE
        for (;;){

            cc112x_data_mode ();
    r = cc112x_tx_pkt(packet, PACKET_SIZE,SINK_MAC_ADDR);
            if (r == TXPKT_SUCCESS) {

                uart_puts("Data was sent\n\r");
               // uart_printf(" sending frame: %d ", r);
            }


            else if (r==TXPKT_WRONG_MODE)
                uart_puts ("you are in the wrong mode\n");

            else
                          uart_puts("Data was not sent\n\r");

            P1OUT ^= 0x01;              // toggle P1.0
                                 for(i=10000; i>0; i--);     // delay
        }



#elif defined SINK
            int src;
           // cc112x_set_rx_timeout(WUP_TIMEOUT);
for (;;){
            // Putting the radio in continuous listening mode
             cc112x_continuous_rx();

                         uart_puts("i am listning\n\r");

                         r = cc112x_rx_pkt(rx_fifo[rx_fifo_last].buffer, &length, &ED_ADDRESS, true);
                                      if (r == RXPKT_CRC_ERR) {
                                          // CRC error means collision usually.
                                          uart_puts("Data was not received\n\r");
                                      }

                                      else if (r == RXPKT_SUCCESS) {
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



#endif
    //_EINT();
    //timer_init();
    //spi_init();

    //PT_INIT(&app_thread_pt, app_thread, NULL);
    //register_thread(&app_thread_pt);

    //start_threads();
}


