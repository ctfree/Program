/*
 * Handling IO interrupts (from ports 1 and 2) using protothread.
 * An interrupt handler can also be a simple function, not a thread, that will be called as soon as the
 * interrupt is raised.
 *
 * Each interrupt is associated with a protothread. When an interrupt arrises
 * on a given port, the protothread associated with this port will be scheduled.
 */

#include <tools/io_interrupts/io_interrupts.h>
#include "../../kernel/sched/sched.h"
#include <sched/sched.h>
#include <stdbool.h>
#include <msp430.h>
#include <stddef.h>
#include <tools/timer/timer.h>

/*
 * Interrupt hanler type
 */
enum interrupt_handler_t
{
	NONE,
	FUNCTION,
	P_THREAD
};

/*
 * Interrupt handler structure.
 */
struct interrupt_handler
{
	enum interrupt_handler_t type;
	union
	{
		// If the handler is a thread
		struct pt *handler_pt;
		// If the handler is a function
		handler_func_t handler_f;
	};
};

/*
 * Handlers
 */
static struct interrupt_handler handlers[2][8] = {NONE, NULL};

/*
 * Initializes IO interrupts.
 */
void io_interrupts_init(void)
{
	P1IE = 0;
	P2IE = 0;
	P1IFG = 0;
	P2IFG = 0;
}

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
void io_interrupts_add_pt_handler(unsigned int port, unsigned int pin, enum it_edge edge, struct pt *handler_thread)
{
	if (port == 1) {
		P1IE |= (1 << pin);
		if (edge == LOW_TO_HIGH) {
			P1IES &= ~(1 << pin);
		} else {
			P1IES |= (1 << pin);
		}
	} else if (port == 2) {
		P2IE |= (1 << pin);
		if (edge == LOW_TO_HIGH) {
			P2IES &= ~(1 << pin);
		} else {
			P2IES |= (1 << pin);
		}
	}
  	handlers[port-1][pin].type = P_THREAD;
  	handlers[port-1][pin].handler_pt = handler_thread;
}

/*
 * Associate a handler with a port.
 *
 * param port: the port number (must be 1 or 2)
 * param pin: the pin on the indicated port
 * param edge: interrupt on low to high or high to low transition
 * param handler: the function that handle the IO. Must be of type void handler(void)
 *
 * If a handler was already associated with the indicated port, it will be replaced.
 */
void io_interrupts_add_func_handler(unsigned int port, unsigned int pin, enum it_edge edge, handler_func_t handler_func)
{
	if (port == 1) {
		P1DIR &= ~(1 << pin);
		P1IE |= (1 << pin);
		if (edge == LOW_TO_HIGH) {
			P1IES &= ~(1 << pin);
		} else {
			P1IES |= (1 << pin);
		}
	} else if (port == 2) {
		P2DIR &= ~(1 << pin);
		P2IE |= (1 << pin);
		if (edge == LOW_TO_HIGH) {
			P2IES &= ~(1 << pin);
		} else {
			P2IES |= (1 << pin);
		}
	}
  	handlers[port-1][pin].type = FUNCTION;
  	handlers[port-1][pin].handler_f = handler_func;
}

/*
 * Remove a handler.
 */
void io_interrupt_remove_handler(int port, int pin)
{
	handlers[port-1][pin].type = NONE;
}

/*
 * Interrupt handlers
 */
#pragma vector=PORT1_VECTOR
__interrupt void port1_handler(void)
{
	int i;
	bool scheduled = false;
	bool is_sleeping = ( (__get_SR_register_on_exit() & CPUOFF) != 0 );

	for (i = 0; i < 8; i++) {
		if ((P1IFG & (1 << i)) != 0) {
			if (handlers[0][i].type == P_THREAD) {
				schedule_thread(handlers[0][i].handler_pt, false);
				scheduled = true;
			} else if (handlers[0][i].type == FUNCTION) {
				scheduled = handlers[0][i].handler_f();
			}
		}
	}

	if (scheduled && is_sleeping) {
		LPM3_EXIT;
	}

	P1IFG = 0;
}

#pragma vector=PORT2_VECTOR
__interrupt void port2_handler(void)
{
	int i;
	bool scheduled = false;
	bool is_sleeping = ( (__get_SR_register_on_exit() & CPUOFF) != 0 );

	for (i = 0; i < 8; i++) {
		if ((P2IFG & (1 << i)) != 0) {
			if (handlers[1][i].type == P_THREAD) {
				schedule_thread(handlers[1][i].handler_pt, false);
				scheduled = true;
			} else if (handlers[1][i].type == FUNCTION) {
				scheduled = handlers[1][i].handler_f();
			}
		}
	}

	if (scheduled && is_sleeping) {
		LPM3_EXIT;
	}

	P2IFG = 0;
}
