/*
 * Include all the principal header files specific to a platform, that is:
 * - the PowWow header file, depending of the used version of PowWow
 * - the radio header file, depending of the used radio chip
 * - RCUP chip header file, is specified
 *
 * The platform specification are given at compile time by defining the appropriate
 * macros.
 */

#ifndef __PLATFORM_H
#define __PLATFORM_H

/*
 * PowWow header file
 */
#if defined MSP2ZIGV_V7
#include <drivers/msp2zigv/msp2zigv_v7/msp2zigv_v7.h>
#endif

/*
 * RCUP chip header file
 */
#if defined RCUP_V4
#include <drivers/rcup/rcup_v4/rcup_v4.h>
#endif

#endif

