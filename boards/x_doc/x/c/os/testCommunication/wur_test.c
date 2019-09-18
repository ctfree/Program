/*
 * wur_test.c
 *
 *  Created on: 22 mai 2018
 *      Author: djidi
 */


/*
 * Application that turn on the LED1 if an interrupt arrise on the
 * port 2.5, supposed to be the wake up interrupt port.
 * Data from WuRx are suppose to arrive on port 2.7.
 */

#include <drivers/platform.h>
#include <tools/io_interrupts/io_interrupts.h>
#include <tools/timer/timer.h>
#include <tools/misc.h>
#include <pt/pt.h>
#include <stddef.h>
#include <sched/sched.h>
#include <drivers/serial/uart/uart.h>
#include <drivers/wurx/wurx.h>

/*
 * Handler of wake up interrupts
 */
void handler_wurx(char *data)
{
    unsigned int addr = *((unsigned int*)data);
    uart_send_uint(addr, 10);
    uart_puts(" i am receiving the interruption \n ");
    P1DIR |= 0x01;                  // configure P1.0 as output

        volatile unsigned int i;        // volatile to prevent optimization

        while(1)
        {
            P1OUT ^= 0x01;              // toggle P1.0
            for(i=10000; i>0; i--);     // delay
        }

    ENABLE_WURX_IT;
}

int main(void)
{


    msp2zigv_init();
    WDT_DISABLE;
    _EINT();
    timer_init();
    uart_init();
    wurx_init(handler_wurx);


    start_threads();
}

