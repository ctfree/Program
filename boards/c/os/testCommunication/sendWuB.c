/*
 * sendWuB.c
 *
 *  Created on: 22 mai 2018
 *      Author: djidi
 */

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


void main (){

    uint8 wub[] = {0x55, 0x6B};
   // uint8 wub[] = { 0x00};
    int r;
      msp2zigv_init();
      WDT_DISABLE;
    //  set_voltage(1);
     // LPM3;
      _EINT();
      timer_init();
      uart_init();
      spi_init();
      uart_puts("beacon to send \n\r");
      // uart_flush();

      // Initalizes the CC1120
      cc112x_init(2u);

for (;;){

    // wub mode
    cc112x_wub_mode ();

    // send wub
    r = cc112x_tx_wub(wub);

    if (r != TXPKT_SUCCESS) {
           uart_puts("beacon was not sent \n\r");
        }

    else
        uart_puts("beacon was sent \n\r");




}


}



