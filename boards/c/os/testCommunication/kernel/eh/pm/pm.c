/*
 * Power manager access point. This module is the glue of the two other
 * power manager subsystems, i.e. the EBE (grapman, fuzzyman,...) and
 * the energy allocator.
 *
 * The power manager run in its own protothread. It will thus be started with the
 * other protothread when start_thread() is called.
 */

#include "../ebe/fuzzyman/fuzzyman.h"
#include "../ea/ea.h"
#include <pm/pm.h>
#include <pt/pt.h>
#include <drivers/platform.h>
#include <stddef.h>
#include <tools/timer/timer.h>
#include <sched/sched.h>
#include <math.h>
#include <config.h>

/*
 * Local packet generation period in 10^-2 sec
 */
static unsigned int _local_gen_period;

/*
 * Residual energy (J) ar the begining of the slot
 */
static float _er;

/*
 * Fuzzyman energy budget (J)
 */
static float _eb;

/*
 * Energy harvested during the previous slot
 */
static float _eh;

/*
 * Estimation of the consumed energy at the previous slot
 */
static float _ec;

/*
 * Supercapacitor voltage measurement
 */
static int _v_store;

/*
 * Used by the app to known if the PM was executed since the last time
 */
static bool _pm_executed;

/*
 * Reads and returns the currently store energy (in mV)
 */
static int measure_v_store(void)
{
	int v_store;

	//increase_voltage();
	v_store = rcup_read_voltages();
	//decrease_voltage();

	if (v_store == RCUP_ERROR) {
		return -1;
	}
	return v_store;
}

/*
 * Convert seconds to low rate timer time unit
 */
static unsigned int convert_time(float x)
{
	return (unsigned int)(x / PERIODIC_TIMER_TICK_DURATION);
}

/*
 * Power manager thread.
 *
 * This thread is executed periodically.
 */
static struct pt pm_thread_pt;
static PT_THREAD(pm_thread(void *args))
{
	float v_store, old_er;

	PT_BEGIN(&pm_thread_pt);

	for ( ;; ) {
		// SLEEPING
		WAIT_EVENT(&pm_thread_pt);

		// Compute the current residual energy
		_v_store = measure_v_store();	// in mV
		if (_v_store < 0) {
			continue;
		}
		v_store = ((float)_v_store)*0.001f;
		old_er = _er;
		_er = 0.5f*ESD_CAPACITANCE*v_store*v_store;

		// Run fuzzyman to compute the energy budget
		_eb = fuzzyman_update_eb(_er, _er - old_er);

		// Calling the enrgy allocator to compute the wake up interval
		_local_gen_period = convert_time(ea_get_local_wakeup_interval(_eb));

		_pm_executed = true;
	}

	PT_END(&pm_thread_pt);
}

/*
 * Initialize the power manager.
 * All the submodules (EBE, energy allocator) are also initialized.
 * This function should be called before the node starts performing measurements
 * or relaying.
 *
 * NOTE: RCUP chip driver must be initialized before calling this function.
 */
void pm_init(void)
{
	rcup_init();

	// Fuzzyman is used here
	fuzzyman_init();

	// Initializing the energy allocator
	ea_init();

	// Initializing the power manager thread
	PT_INIT(&pm_thread_pt, pm_thread, NULL);
	register_thread(&pm_thread_pt, true);
	// The PM thread is executed periodically, at the begining of every slot
	set_periodic_timer(&pm_thread_pt, TIME_SLOT / PERIODIC_TIMER_TICK_DURATION);

	// Initialize residual energy
	do {
		_v_store = measure_v_store();
	} while (_v_store < 0);
	float v_store = ((float)_v_store)*0.001f;
	_er = 0.5f*ESD_CAPACITANCE*v_store*v_store;

	// Initial local packet generation period computation
	_eb = fuzzyman_get_current_eb();
	_local_gen_period = convert_time(ea_get_local_wakeup_interval(_eb));

	_pm_executed = true;
}

/*
 * Returns the last computed value of the local packet generation period.
 *
 * The protothread that generate packets locally (i.e. performs sensing) should
 * run with the period obtained by calling this method.
 * NOTE: it is assumed that the thread that generates packets locally generate ONE packet
 * per run. Then it goes to sleep.
 */
unsigned int pm_get_t_gen(void)
{
	return _local_gen_period;
}

/* ------------------------------------------------------------------------------------------
 * For debug and tracking
 */
/*
 * Returns the estimation of the energy consummed during the previous slot
 */
float pm_get_ec(void)
{
	return _ec;
}

/*
 * Returns the residual energy measured at the begining of the slot
 */
float pm_get_er(void)
{
	return _er;
}

/*
 * Returns the estimated harvested energy
 */
float pm_get_eh(void)
{
	return _eh;
}

/*
 * Returns the energy budget computed by Fuzzyman
 */
float pm_get_eb(void)
{
	return _eb;
}

/*
 * Returns vstore as it was readen
 */
int pm_get_vstore(void)
{
	return _v_store;
}

/*
 * Was the PM executed since the last call ?
 */
bool pm_executed(void)
{
	bool exec = _pm_executed;
	_pm_executed = false;
	return exec;
}
