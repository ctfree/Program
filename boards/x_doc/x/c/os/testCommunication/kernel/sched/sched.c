/*
 * Scheduler intefaces.
 *
 * The scheduler used here is basic and non preemtive.
 */

#include <stdbool.h>
#include <msp430.h>
#include <pt/pt.h>
#include <tools/timer/timer.h>

#define RUN_QUEUE_SIZE	20
static struct pt *run_queue[RUN_QUEUE_SIZE];
static int rq_next_thread_to_run = 0;	/* Next thread to run in the run queue */
static int rq_next_available_spot = 0; /* Next available spot in the run queue */
#define RQ_NEXT(i) (((i) + 1) % RUN_QUEUE_SIZE)

/*
 * Add a (proto)thread to the run queue.
 * Execution of the threads is NOT started. 
 *
 * NOTE: if the thread is already in the run queue, it will not be added twice
 * NOTE2: run queue overflow is NOT checked.
 */
static void add_to_run_queue(struct pt *thread, bool it_enabled)
{
	int i;

	if (it_enabled) {
		_DINT();
	}

	/* Checking if the thread is not already in the run queue */
	for (i = rq_next_thread_to_run; i != rq_next_available_spot; ) {
		if (run_queue[i] == thread) {
			return;
		}
		i = RQ_NEXT(i);
	}
	run_queue[rq_next_available_spot] = thread;
	rq_next_available_spot = RQ_NEXT(rq_next_available_spot);

	if (it_enabled) {
		_EINT();
	}
}

/*
 * Add a (proto)thread to the run queue.
 * Execution of the threads is NOT started. 
 *
 * NOTE: if the thread is already in the run queue, it will not be added twice
 * NOTE2: run queue overflow is NOT checked.
 */
void register_thread(struct pt *thread, bool it_enabled)
{
	add_to_run_queue(thread, it_enabled);
}

/*
 * Add a (proto)thread to the run queue.
 * Execution of the threads is NOT started.
 *
 * NOTE: if the thread is already in the run queue, it will not be added twice
 * NOTE2: run queue overflow is NOT checked.
 */
void schedule_thread(struct pt *thread, bool it_enabled)
{
	add_to_run_queue(thread, it_enabled);
}

/*
 * Start running threads in the run queue
 */
void start_threads(void)
{
	for ( ;; ) {
		int thread_to_run;

		_DINT();

		/* No thread to run: going to sleep */
		if (rq_next_thread_to_run == rq_next_available_spot) {
			_EINT();
			LPM3;
		}

		thread_to_run = rq_next_thread_to_run;
		rq_next_thread_to_run = RQ_NEXT(rq_next_thread_to_run);
		if (run_queue[thread_to_run]->started) {
			run_queue[thread_to_run]->wait = false;
		} else {
			run_queue[thread_to_run]->started = true;
		}
		_EINT();
		PT_SCHEDULE(run_queue[thread_to_run]);
	}
}
