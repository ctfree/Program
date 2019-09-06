/*
 * Wake up radio driver.
 *
 * A protothread is dedicated to handle WuRx interrupt.
 *
 * The wake-up radio is supposed to be connected to the MSP2SIGV PCB using
 * 	via two PORTS:
 * 		2.5: for wake up interrupt
 * 		2.7: for data
 * 	Communication between the WuRx and MSP2ZIGV is done using Manchester modulation.
 */

#include <sched/sched.h>
#include <drivers/wurx/wurx.h>
#include <pt/pt.h>
#include <tools/io_interrupts/io_interrupts.h>
#include <stddef.h>
#include <tools/timer/timer.h>
#include <stdbool.h>
#include <msp430.h>
#include "../../kernel/sched/sched.h"

/*
 * WuRx interrupt handler function
 */
static struct pt *_wurx_thread = NULL;

/*
 * Function that handles WuRx interrupts.
 *
 * NOTE: WuRx ITs are disabled before scheduling the handler thread.
 */
static bool _wurx_it_handle(void)
{
	DISABLE_WURX_IT;
	// modified by nour (it was false)
	schedule_thread(_wurx_thread,false);
	return true;
}

/* Initialize WuRx driver.
 * 
 * param thread_wurx: thread to schedule when a WuRx interrupt arrises.
 * 	The thread will be scheduled only if the node is not sleeping.
 */
void wurx_init(struct pt *thread_wurx)
{
	_wurx_thread = thread_wurx;

	// Set the interrupt handler for WuRx interrupt
	io_interrupts_add_func_handler(2, 5, LOW_TO_HIGH, _wurx_it_handle);

	// Set the P2.7 as an input to receive data from the WuRx
	P2DIR &= ~BIT7;
}
