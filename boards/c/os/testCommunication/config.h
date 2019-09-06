/*
 * Contains cross-modules node specific constants.
 */

#ifndef __CONFIG_H
#define __CONFIG_H

/*
 * Time slot duration (in second)
 */

#define TIME_SLOT	10u

/*
 * Capacitance (in F) of the supercap
 */
#define ESD_CAPACITANCE	0.9

/*
 * For DASIP DEMO
*/

#define SINK_ADDRESS	0x1u
#define ED_ADDRESS		0x2u
//#define PKT_SIZE		sizeof(float)

// What are we: comment what we are not
//#define SINK
#define ED

#ifdef SINK

#define SELF_MAC_ADDRESS	SINK_ADDRESS




#elif defined(ED)

#define SELF_MAC_ADDRESS	ED_ADDRESS

#endif

#endif

