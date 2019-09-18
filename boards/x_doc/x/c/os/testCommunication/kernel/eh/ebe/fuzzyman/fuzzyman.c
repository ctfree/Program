// --------------------------------------------------------------------------
// Fuzzyman: an energy budget estimator using a fuzzy controller.
// -------------------------------------------------------------------------

#include "fuzzyman.h"
#include <config.h>


// ----------- Fuzzyman parameter
// Minimal energy budget
#define EB_MIN	1e-3 // Joule. TODO
// ----- Residual energy fuzzy sets threshold
#define EMTPY_THR	1	//TODO
#define FULL_THR	2	// TODO
// ----- Delta residual energy fuzzy sets threshold
#define NEG_THR		-1	// TODO
#define POS_THR		1	// TODO
// ------ Fuzzy rules parameters
#define A_E_N	1	// Coefficient for rule (Empty,Neg) TODO
#define A_E_Z	2	// Coefficient for rule (Empty,Zero) TODO
#define A_E_P	3	// Coefficient for rule (Empty,Pos) TODO
#define A_F_N	4	// Coefficient for rule (Full,Neg) TODO
#define A_F_Z	5	// Coefficient for rule (Full,Zero) TODO
#define A_F_P	6	// Coefficient for rule (Full,Pos) TODO

// ------------------ Membership functions
float mu_empty(float x)
{
	if (x < EMTPY_THR) {
		return 1.0f;
	} else if (x < FULL_THR) {
		return (FULL_THR - x) / (FULL_THR - EMTPY_THR);
	} else {
		return 0.0f;
	}
}

float mu_full(float x)
{
	if (x < EMTPY_THR) {
		return 0.0f;
	} else if (x < FULL_THR) {
		return (x - EMTPY_THR) / (FULL_THR - EMTPY_THR);
	} else {
		return 1.0f;
	}
}

float mu_neg(float x)
{
	if (x < NEG_THR) {
		return 1.0f;
	} else if (x < 0.0f) {
		return x/NEG_THR;
	} else {
		return 0.0f;
	}
}

float mu_zero(float x)
{
	if (x < NEG_THR) {
		return 0.0f;
	} else if (x < 0.0f) {
		return 1.0f - x/NEG_THR;
	} else if (x < POS_THR) {
		return 1.0f - x/POS_THR;
	} else {
		return 0.0f;
	}
}

float mu_pos(float x)
{
	if (x < 0.0f) {
		return 0.0f;
	} else if (x <POS_THR) {
		return x/POS_THR;
	} else {
		return 1.0f;
	}
}

// ------------------------ Private variable
static float _eb;	// Current energy budget (J)

// --------------------------------- Fuzzyman algorithm

/*
 * Compute the power that the node should consumes.
 *
 * param er: Current residual energy.
 * param der: Residual energy variation
 *
 * 	Returns what the energy budget (J).
 */
float fuzzyman_update_eb(float er, float der)
{
	// Fuzzyfication: Compute the membership values of each fuzzy set
	float empty = mu_empty(er);
	float full = mu_full(er);
	float neg = mu_neg(der);
	float zer = mu_zero(der);
	float pos = mu_pos(der);

	// Compute the rules activation values for each rule
	_eb = 0.0f;
	float sum_act_val = 0.0f;
	float act_val;

	// EMPTY - NEG
	act_val = empty*neg;
	_eb += act_val*A_E_N;
	sum_act_val += act_val;

	// EMPTY - ZER
	act_val = empty*zer;
	_eb += act_val*A_E_Z;
	sum_act_val += act_val;

	// EMPTY - POS
	act_val = empty*pos;
	_eb += act_val*A_E_P;
	sum_act_val += act_val;

	// FULL - NEG
	act_val = full*neg;
	_eb += act_val*A_F_N;
	sum_act_val += act_val;

	// FULL - ZER
	act_val = full*zer;
	_eb += act_val*A_F_Z;
	sum_act_val += act_val;

	// FULL - POS
	act_val = full*pos;
	_eb += act_val*A_F_P;
	sum_act_val += act_val;

	_eb = _eb*er / sum_act_val;

	return _eb;
}

/*
 * Return the current energy budget (J)
 */
float fuzzyman_get_current_eb(void)
{
	return _eb;
}

/*
 * Initialize Fuzzyman
 */
void fuzzyman_init(void)
{
	_eb = EB_MIN;
}
