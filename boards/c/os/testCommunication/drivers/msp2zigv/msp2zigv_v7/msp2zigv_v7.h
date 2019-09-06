/*
 * PowWow v7 plateform specifics.
 */

#ifndef __MSP2ZIGV_H
#define __MSP2ZIGV_H


#include <msp430.h>

/*
 * PowWow has 4 LEDs that can be used using the following
 * macros
 */
#define LED1_ON    P1OUT|=BIT0
#define LED1_OFF   P1OUT&=(~BIT0)
#define LED1_TOG   P1OUT^=BIT0

#define LED2_ON    P1OUT|=BIT1
#define LED2_OFF   P1OUT&=(~BIT1)
#define LED2_TOG   P1OUT^=BIT1

#define LED3_ON    P1OUT|=BIT2
#define LED3_OFF   P1OUT&=(~BIT2)
#define LED3_TOG   P1OUT^=BIT2

#define LED4_ON    P1OUT|=BIT3
#define LED4_OFF   P1OUT&=(~BIT3)
#define LED4_TOG   P1OUT^=BIT3

/*
 * PowWow has 2 buttons that can be used using the following macros
 */
#define SW1_STATE	(P1IN&BIT6)
#define SW1_PUSHED	(P1IN&BIT6 == (~BIT6))
#define EN_SW1_IT	(P1IE |= BIT6)
#define DE_SW1_IT	(P1IE &= ~BIT6)
#define RST_SW1_IT	(P1IFG &= ~BIT6)

#define SW2_STATE	(P1IN&BIT7)
#define SW2_PUSHED	(P1IN&BIT7 == (~BIT7))
#define EN_SW2_IT	(P1IE |= BIT7)
#define DE_SW2_IT	(P1IE &= ~BIT7)
#define RST_SW2_IT	(P1IFG &= ~BIT7)

/*
 * Initialize PowWow.
 */
void msp2zigv_init(void);

/*
 * Change the voltage (DVS)
 *
 * param new_voltage can take values between 1 and 4, corresponding to:
 * 	1 : 1.9V
 * 	2 : 2.1V
 * 	3 : 2.7V
 * 	4 : 3.3V
 */
void set_voltage(int new_voltage);

/*
 * Increase voltage from 1 step
 */
void increase_voltage(void);

/*
 * Decrease voltage from one step
 */
void decrease_voltage(void);

/*
 * Return current voltage step:
 *  1 : 1.9V
 * 	2 : 2.1V
 * 	3 : 2.7V
 * 	4 : 3.3V
 */
int get_voltage(void);

#endif

