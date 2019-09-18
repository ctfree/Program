/*
 * This module compute the local generation rate and the
 * reception rate in order to ensure that the node consumes the power
 * required by the EBE (GRAPMAN, FUZZYMAN, or any other.
 *
 * Internal interface.
 */

#ifndef __EA_H
#define __EA_H

/*
 * Initialize the energy allocator
 */
void ea_init(void);
/*
 * Compute the wake up interval corresponding to an energy budget.
 */
float ea_get_local_wakeup_interval(float eb);


#endif
