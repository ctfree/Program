/*
 * Handling IO interrupts (from ports 1 and 2) using protothread.
 *
 * Each interrupt is associated with a protothread. When an interrupt arrises
 * on a given port, the protothread associated with this port will be scheduled.
 */

#ifndef __IO_INTERRUPTS_H
#define __IO_INTERRUPTS_H

#include <pt/pt.h>

/*
 * Interrupt edge transision
 */
enum it_edge
{
	LOW_TO_HIGH,
	HIGH_TO_LOW
};

/*
 * Interrupt handler function type.
 * The prototype must be:
 * bool handler_func(void);
 * where the returned boolean indicates if the node should leave the sleep mode.
 */
typedef bool (*handler_func_t)(void);

/*
 * Initializes IO interrupts.
 */
void io_interrupts_init(void);

/*
 * Associate a handler with a port.
 *
 * param port: the port number (must be 1 or 2)
 * param pin: the pin on the indicated port
 * param edge: interrupt on low to high or high to low transition
 * param handler: the thread that handle the IO
 *
 * If a handler was already associated with the indicated port, it will be replaced.
 */
void io_interrupts_add_pt_handler(unsigned int port, unsigned int pin, enum it_edge edge, struct pt *handler_thread);

/*
 * Associate a handler with a port.
 *
 * param port: the port number (must be 1 or 2)
 * param pin: the pin on the indicated port
 * param edge: interrupt on low to high or high to low transition
 * param handler: the function that handle the IO. Must be of type bool handler(void)
 *
 * If a handler was already associated with the indicated port, it will be replaced.
 */
void io_interrupts_add_func_handler(unsigned int port, unsigned int pin, enum it_edge edge, handler_func_t handler_func);

/*
 * Remove a handler.
 */
void io_interrupt_remove_handler(int port, int pin);

#endif

