/*
 * Kernel scheduler intefaces.
 *
 * The scheduler used here is basic and non preemtive.
 */

#ifndef __KERN_SCHED_H
#define __KERN_SCHED_H

#include <stdbool.h>
#include <pt/pt.h>

/*
 * Is the node sleeping.
 * Interrupt handlers can use it to know if the node was sleeping
 * before the interrupt.
 */
//extern bool is_sleeping;

#endif

