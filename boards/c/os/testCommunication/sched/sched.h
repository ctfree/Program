/*
 * Scheduler intefaces.
 *
 * The scheduler used here is basic and non preemtive.
 */

#ifndef __SCHED_H
#define __SCHED_H

#include <pt/pt.h>

/*
 * Put the (proto)thread in sleep mode (LPM3) until the next event
 * (IO interrupts or timer trigger).
 *
 * If other threads were waiting to be scheduled, then they will be schedule before
 * putting the  node in sleep mode. This could happen if interrupts arrise while
 * the calling thread was running, putting the other threads in a "wait queue".
 */
#define WAIT_EVENT(pt) \
	do {	\
		LC_SET((pt)->lc);	\
		if ((pt)->wait) {	\
			return PT_THREAD_WAITING; \
		} else {	\
			(pt)->wait = true;	\
		}	\
	} while(0)

/*
 * Add a (proto)thread to the run queue.
 * Execution of the threads is NOT started. 
 *
 * NOTE: if the thread is already in the run queue, it will not be added twice
 * NOTE2: run queue overflow is NOT checked.
 */
void register_thread(struct pt *thread, bool it_enabled);

/*
 * Start running threads in the run queue
 *
 * Returns only if no thread to run was found.
 */
void start_threads(void);

/*
 * Add a (proto)thread to the run queue.
 * Execution of the threads is NOT started.
 *
 * NOTE: if the thread is already in the run queue, it will not be added twice
 * NOTE2: run queue overflow is NOT checked.
 */
void schedule_thread(struct pt *thread, bool it_enabled);

/*
 * Is the node sleeping ?
 */
bool is_sleeping(void);

#endif

