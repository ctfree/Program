/*
 * Power manager access point. This module is the glue of the two other
 * power manager subsystems, i.e. the EBE (grapman, fuzzyman,...) and
 * the energy allocator
 *
 * The power manager run in its own protothread. It will thus be started with the
 * other protothread when start_thread() is called.
 *
 * Application interface.
 */

#ifndef __POWER_MANAGER_H
#define __POWER_MANAGER_H

#include <stdbool.h>

/*
 * Initialize the power manager.
 * All the submodules (EBE, energy allocator) are also initialized.
 * This function should be called before the node starts performing measurements
 * or relaying.
 * RCUP is also initialized.
 *
 */
void pm_init(void);

/*
 * Returns the last computed value of the local packet generation period.
 *
 * The protothread that generate packets locally (i.e. performs sensing) must
 * run with the period obtained by calling this method.
 * NOTE: it is assumed that the thread that generates packets locally generate ONE packet
 * per run. Then it goes to sleep.
 */
unsigned int pm_get_t_gen(void);

/* ------------------------------------------------------------------------------------------
 * For debug and measurements
 */
/*
 * Returns the estimation of the energy consummed during the previous slot
 */
float pm_get_ec(void);

/*
 * Returns the residual energy measured at the begining of the slot
 */
float pm_get_er(void);

/*
 * Returns the estimated harvested energy
 */
float pm_get_eh(void);

/*
 * Returns the energy budget computed by Fuzzyman
 */
float pm_get_eb(void);

/*
 * Returns vstore as it was readen
 */
int pm_get_vstore(void);

/*
 * Was the PM executed since the last call ?
 */
bool pm_executed(void);

#endif
