/*
 * Fuzzyman: an EBE based on fuzzy control
 */

#ifndef __FUZZYMAN_INTERFACE_H
#define __FUZZYMAN_INTERFACE_H

/*
 * Initialize Fuzzyman
 */
void fuzzyman_init(void);

/*
 * Compute the power that the node should consumes.
 *
 * param er: Current residual energy.
 * param der: Residual energy variation
 *
 * 	Returns what the energy budget (J).
 */
float fuzzyman_update_eb(float er, float der);

/*
 * Return the current energy budget (J)
 */
float fuzzyman_get_current_eb(void);

#endif

