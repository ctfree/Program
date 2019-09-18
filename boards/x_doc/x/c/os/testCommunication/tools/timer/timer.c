/*
 * Useful functions to use MSP430 timers.
 *
 * Periodic timer: use it to get some periodic task.
 * 	Very low frequency timer: 512 Hz, 1 tick = 1.953ms
 * 	Max value: 127.998 s
 *
 * One shot active timer and stop watch. Only one one shot active timer and one stopwatch can
 * be running at a given time.
 * Two modes are available: high rate and low rate.
 * 	High rate: 4096 Hz, Tick duration = 0.244 ms, Max value: 15.9998 s
 * 	Low rate: 512 Hz, Tick duration: 1.953 ms,
 */

#include <msp430.h>
#include <stddef.h>
#include "../../kernel/sched/sched.h"
#include <sched/sched.h>
#include <pt/pt.h>
#include <tools/timer/timer.h>


// Number of periodic timer
static unsigned int _periodic_timers_count = 0u;
// We keep the threads that must be awaken for each periodic timer
struct _periodic_timer_t
{
	struct pt *thread;
	unsigned int period;
};
static struct _periodic_timer_t _periodic_timers[MAX_PERIODIC_TIMERS];

// Is stopwatch running ?
static bool _stopwatch_running = false;
// Is one shot timer running ?
static bool _one_shot_running = false;
// Has one shot timer expired ?
static bool _one_shot_expired = false;
// Thread to schedule when the one shot timer expired. If null, nothing will be done
#define SLEEP_ONE_SHOT_COUNT	15
static struct
{
	struct pt *thread;
	uint16 time_remaining;
} _sleep_timer_threads[SLEEP_ONE_SHOT_COUNT] = {{NULL, 0u}};
static int _one_shot_sleep_count = 0;
static uint16 _osl_last_time = 0u;
// Rate of the timer b
enum tb_rate_t _tb_rate = HIGH_RATE;
// Local time
static uint32 _local_time = 0u;

// Periodic timer tick duration
const float PERIODIC_TIMER_TICK_DURATION = 1.953e-3f;


/*
 * Initialize the timer module. This function must be called before any operation
 * on the timers are done.
 *
 * Interrupt MUST BE ENABLED for the timer module to work.
 */
void timer_init(void)
{
	TACTL = TACLR;  // Timer A clear
	TACTL = TASSEL_1 | ID_3 | TAIE;	// Using ACLK clock and divied /8, 16 bits counter length
	TACTL |= MC_2;	// Starting timer A

	TBCTL = TBCLR;  // Timer B clear
	TBCTL = TBSSEL_1;	// Using ACLK clock and divied /1 (high rate), 16 bits counter length
}

/*
 * Set a periodic timer. An interrupt will arise periodically and wake up the thread.
 *
 * Use the WAIT_EVENT() macro to go to sleep and wait for the next interrupt.
 *
 * Returns the id of the timer, or -1 if no period timers are available
 */
int set_periodic_timer(struct pt *thread, unsigned int timer_value)
{
	if (_periodic_timers_count == MAX_PERIODIC_TIMERS) {
		return -1;
	}

	int timer_id = _periodic_timers_count;

	_periodic_timers[_periodic_timers_count].thread = thread;
	_periodic_timers[_periodic_timers_count].period = timer_value;
	_periodic_timers_count++;
	if (_periodic_timers_count == 1u) {
		TACCR0 = timer_value;
		TACCTL0 |= CCIE;
	} else {
		TACCR1 = TAR + timer_value;
		TACCTL1 |= CCIE;
	}

	return timer_id;
}

/*
 * Change a periodic timer value.
 * You must use the ID returned by the 'set_periodic_timer' function.
 */
void change_periodic_timer(int timer_id, unsigned int new_value)
{
	_periodic_timers[timer_id].period = new_value;
	if (timer_id == 0) {
		TACCR0 = TAR + new_value;
	} else {
		TACCR1 = TAR + new_value;
	}
}

/*
 * Returns true if a timer is available, false otherwise
 */
bool is_periodic_timer_available(void)
{
	return (_periodic_timers_count < MAX_PERIODIC_TIMERS);
}

/*
 * Set the one shot time.
 * Only one one shot timer can be used at a given time, and timer expiration must be checked using
 * 	has_one_shot_timer_expired().
 *
 *
 * Only one one shot timer can run at the time.
 * If an accurate timer was already set, it will be cancelled.
 */
void set_one_shot_timer(unsigned int duration)
{
	TBCCTL0 &= ~CCIE;

	if (0xFFFFu - TBR >= duration) {
		TBCCR0 = TBR + duration;
	} else {
		TBCCR0 = duration - (0xFFFFu - TBR);
	}

	if (!_one_shot_running && !_stopwatch_running) {
		// Starting the timer B is nothing was running
		TBCTL |= MC_2;
	}

	_one_shot_running = true;
	_one_shot_expired = false;

	// TODO: new
	// Clean interrupts
	TBCCTL0 &= ~CCIFG;
	TBCCTL0 |= CCIE;
}

/*
 * Reset the accurate timer
 */
void reset_one_shot_timer(void)
{
	_one_shot_expired = false;
}

/*
 * Returns true if the accurate timer has expired, false otherwise.
 */
bool has_one_shot_timer_expired(void)
{
	return _one_shot_expired;
}

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
#define SLP_PREC	1u	// ~2ms
void set_one_shot_timer_sleep(unsigned int duration, struct pt *thread)
{
	TACCTL2 &= ~CCIE;	// Mask interrupts for CCR 2

	uint16 elapsed;
	if (TAR >= _osl_last_time) {
		elapsed = TAR - _osl_last_time;
	} else {
		elapsed = (0xFFFFu - _osl_last_time) + TAR;
	}

	int avl_index = -1;
	int i;
	for (i = 0; i < SLEEP_ONE_SHOT_COUNT; i++) {
		if (_sleep_timer_threads[i].thread == thread) {
			avl_index = i;
		} else if ((avl_index == -1) && (_sleep_timer_threads[i].thread == NULL)) {
			avl_index = i;
		} else if (_sleep_timer_threads[i].thread != NULL) {
			_sleep_timer_threads[i].time_remaining -= elapsed;
			if (_sleep_timer_threads[i].time_remaining < SLP_PREC) {
				schedule_thread(_sleep_timer_threads[i].thread, true);
				_sleep_timer_threads[i].thread = NULL;
				_one_shot_sleep_count--;
			}
		}
	}

	if (duration >= SLP_PREC) {
		if (avl_index != -1) {
			_sleep_timer_threads[avl_index].thread = thread;
			_sleep_timer_threads[avl_index].time_remaining = duration;
			_one_shot_sleep_count++;
		}
	} else {
		// If the duration is lower than the timer resolution, we just schedule the thread now now...
		schedule_thread(thread, true);
		// If the thread was in the waiting list, we withdraws
		if (avl_index != -1) {
			_sleep_timer_threads[avl_index].thread = NULL;
			_one_shot_sleep_count--;
		}
	}

	uint16 min = 0xFFFFu;
	for (i = 0; i < SLEEP_ONE_SHOT_COUNT; i++) {
		if ((_sleep_timer_threads[i].thread != NULL) && (_sleep_timer_threads[i].time_remaining < min)) {
			min = _sleep_timer_threads[i].time_remaining;
		}
	}

	TACCR2 = TAR + min;
	_osl_last_time = TAR;
	TACCTL2 &= ~CCIFG;	// Reset interrupt flag
	TACCTL2 |= CCIE;	// Enable interrupts
}

#pragma vector=TIMERA0_VECTOR
__interrupt void timerA_interrupt_handler(void)
{
	// --------------------------------------------------
	// Periodic timer 0
	// --------------------------------------------------

	bool scheduled = false;
	bool is_sleeping = ( (__get_SR_register_on_exit() & CPUOFF) != 0 );

	if ((TACCR0 == TAR) && (_periodic_timers[0].thread != NULL)) {
		schedule_thread(_periodic_timers[0].thread, false);
		scheduled = true;
		if (0xFFFFu - TACCR0 > _periodic_timers[0].period) {
			TACCR0 += _periodic_timers[0].period;
		} else {
			TACCR0 = _periodic_timers[0].period - (0xFFFFu - TACCR0);
		}
	}

	if (scheduled && is_sleeping) {
		LPM3_EXIT;
	}
}

#pragma vector=TIMERA1_VECTOR
__interrupt void timerA1_interrupt_handler(void)
{
	bool scheduled = false;
	bool is_sleeping = ( (__get_SR_register_on_exit() & CPUOFF) != 0 );

	// --------------------------------------------------
	// Periodic timer 1
	// --------------------------------------------------
	if ((TACCR1 == TAR) && (_periodic_timers[1].thread != NULL)) {
		schedule_thread(_periodic_timers[1].thread, false);
		scheduled = true;
		if (0xFFFFu - TACCR1 > _periodic_timers[1].period) {
			TACCR1 += _periodic_timers[1].period;
		} else {
			TACCR1 = _periodic_timers[1].period - (0xFFFFu - TACCR1);
		}
		TACCTL1 &= ~CCIFG;
	}

	// -------------------------------------------------
	// One shot timer sleep
	// -------------------------------------------------
	if (TACCR2 == TAR) {
		uint16 elapsed;
		if (TAR > _osl_last_time) {
			elapsed = TAR - _osl_last_time;
		} else {
			elapsed = (0xFFFFu - _osl_last_time) + TAR;
		}
		int i;
		uint16 min = 0xFFFFu;
		for (i = 0; i < SLEEP_ONE_SHOT_COUNT; i++) {
			if (_sleep_timer_threads[i].thread != NULL) {
				_sleep_timer_threads[i].time_remaining -= elapsed;
				if (_sleep_timer_threads[i].time_remaining < SLP_PREC) {
					scheduled = true;
					schedule_thread(_sleep_timer_threads[i].thread, false);
					_sleep_timer_threads[i].thread = NULL;
					_one_shot_sleep_count--;
				} else {
					if (_sleep_timer_threads[i].time_remaining < min) {
						min = _sleep_timer_threads[i].time_remaining;
					}
				}
			}
		}
		TACCTL2 &= ~CCIFG;	// Reset interrupt flag
		if (_one_shot_sleep_count == 0) {
			TACCTL2 &= ~CCIE;	// Mask interrupt for CCR 2
		} else {
			TACCR2 = TAR + min;	// Next interrupt
			_osl_last_time = TAR;
		}
	}

	if (TACTL & TAIFG) {
		_local_time  += 0xFFFFu;
		TACTL &= ~TAIFG;
	}

	if (scheduled && is_sleeping) {
		LPM3_EXIT;
	}
}

#pragma vector=TIMERB0_VECTOR
__interrupt void timerB_interrupt_handler(void)
{
	// --------------------------------------------
	// One shot without sleeping and stopwatch
	// --------------------------------------------

	/* Reset the intertupt flag */
	TBCCTL0 &= ~TBIFG;

	/* Mask interrupt */
	TBCCTL0 &= ~CCIE;

	_one_shot_expired = true;
	_one_shot_running = false;

	if (!_one_shot_running && !_stopwatch_running) {
		// We can stop timer B if not used
		TBCTL &= ~MC_3;
	}
}

