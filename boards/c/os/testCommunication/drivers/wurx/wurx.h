/*
 * Wake up radio driver - Application interface
 *
 * A protothread is scheduled for execution when a wake up interrupt arrises ONLY
 * IF THE NODE IS NOT SLEEPING.
 *
 * The wake-up radio is supposed to be connected to the MSP2SIGV PCB using
 * 	via one port:
 * 		2.5: for wake up interrupt
 * 		2.7: DATA
 */

#ifndef WURX_DRIVER_H
#define WURX_DRIVER_H

#include <pt/pt.h>
#include <drivers/hal_types.h>

/*
 * Disable/Enable WuRx IT
 */
#define DISABLE_WURX_IT (P2IE &= ~BIT5)
#define ENABLE_WURX_IT  (P2IE |= BIT5)

/* Initialize WuRx driver.
 * 
 * param thread_wurx: thread to schedule when a WuRx interrupt arrises.
 * 	The thread will be scheduled only if the node is not sleeping.
 */
void wurx_init(struct pt *thread_wurx);

/* Get the status of the WuRx data pin
 */
#define WURX_DATA_PIN	(P2IN & BIT7)

#endif

