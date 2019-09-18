/*
 * This module compute the local generation rate and the
 * reception rate in order to ensure that the node consumes the power
 * required by the EBE (GRAPMAN, FUZZYMAN, or any other
 */

#include <pm/pm.h>
#include <stdlib.h>
#include <config.h>
#include <pm/pm.h>

/*
 * Initialize the energy allocator
 */
void ea_init(void)
{
	// Nothing to do here
}

/*
 * Compute the wake up interval corresponding to an energy budget.
 */
float ea_get_local_wakeup_interval(float eb)
{
	// TODO
	return 2.0f; // 2s
}
