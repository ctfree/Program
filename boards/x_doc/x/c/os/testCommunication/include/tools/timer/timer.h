/*
 * Useful functions to use MSP430 timers.
 *
 * Periodic timer: use it to get some periodic task.
 * 	Very low frequency timer: 512 Hz, Tick interval = 1.953ms, Max value: 127.998 s
 *
 * One shot active timer and stop watch. Only one one shot active timer and one stopwatch can
 * be running at a given time.
 * Two modes are available: high rate and low rate.
 * 	High rate: 4096 Hz, Tick duration = 0.244 ms, Max value: 15.9998 s
 * 	Low rate: 512 Hz, Tick duration: 1.953 ms, Max value: 127.998 s
 */

#ifndef __TIMER_H
#define __TIMER_H

#include <stdbool.h>
#include <pt/pt.h>
#include <drivers/hal_types.h>

#define MAX_PERIODIC_TIMERS	2u

enum tb_rate_t
{
	LOW_RATE,
	HIGH_RATE,
};

// Periodic timer tick duration
extern const float PERIODIC_TIMER_TICK_DURATION;

/*
 * Initialize the timer module. This function must be called before any operation
 * on the timers are done.
 *
 * Interrupt MUST BE ENABLED for the timer module to work.
 */
void timer_init(void);

/*
 * Set a periodic timer. An interrupt will arise periodically and wake up the thread.
 *
 * Use the WAIT_EVENT() macro to go to sleep and wait for the next interrupt.
 *
 * Returns the id of the timer, or -1 if no period timers are available
 */
int set_periodic_timer(struct pt *thread, unsigned int timer_value);

/*
 * Change a periodic timer value.
 * You must use the ID returned by the 'set_periodic_timer' function.
 */
void change_periodic_timer(int timer_id, unsigned new_value);

/*
 * Returns true if a timer is available, false otherwise
 */
bool is_periodic_timer_available(void);

/*
 * Set the one shot time.
 * Only one one shot timer can be used at a given time, and timer expiration must be checked using
 * 	has_one_shot_timer_expired().
 *
 *
 * Only one one shot timer can run at the time.
 * If an accurate timer was already set, it will be cancelled.
 */
void set_one_shot_timer(unsigned int duration);

/*
 * Reset the accurate timer
 */
void reset_one_shot_timer(void);

/*
 * Returns true if the accurate timer has expired, false otherwise.
 */
bool has_one_shot_timer_expired(void);

/*
 * Set the one shot time.
 * Only one one shot timer can be used at a given time.
 * When the timer expires, 'thread' will be scheduled, and the node will be awaken if it
 * was sleeping.
 *
 * RATE = 512 Hz
 *
 * Only one one shot timer can run at the time.
 * If an accurate timer was already set, it will be cancelled.
 */
void set_one_shot_timer_sleep(unsigned int duration, struct pt *thread);

#endif
