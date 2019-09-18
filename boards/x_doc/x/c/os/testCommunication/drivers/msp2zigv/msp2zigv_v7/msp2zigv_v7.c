/*
 * PowWow v7 plateform specifics.
 */

#include <msp430.h>
#include <tools/misc.h>

/* Current DVS value */
static int current_dvs;

/*
 * Initializa PowWow.
 *
 * - Setup LEDs/DVS/Switches ports
 * - Voltage is by default set to the maximum value (3.3V)
 */
void msp2zigv_init(void)
{
	msp430_init();

	// LED1..4, SW1,2, and SET1,2 are all mapped on port 1
	P1DIR = BIT0 + BIT1 + BIT2 + BIT3 + BIT4 + BIT5;
	P1OUT = BIT4 + BIT5;	// Initialiazing to the maximum voltage (3.3V)
	current_dvs = 4;
}

/*
 * Change the voltage (DVS)
 *
 * param new_voltage can take values between 1 and 4, corresponding to:
 * 	1 : 1.9V
 * 	2 : 2.1V
 * 	3 : 2.7V
 * 	4 : 3.3V
 */
void set_voltage(int new_voltage)
{
	switch(new_voltage)
	{
	case 1 : //minimum voltage : 1.9V, SET1 and SET2 are ON (pulled down)
		P1OUT &= (~BIT4);
		P1OUT &= (~BIT5);
		break;
	case 2 : //voltage : 2.1V, SET1 is OFF (pulled up) and SET2 is ON (pulled down)
		P1OUT |= BIT4;
		P1OUT &= (~BIT5);
		break;
	  
	case 3 : //voltage : 2.7V, SET1 is ON (pulled down) and SET2 is OFF (pulled up)
		 P1OUT |= BIT5;
		 P1OUT &= (~BIT4);
		 break;
	  
	case 4 : //voltage : 3.3V, SET1 and SET 2 are OFF (pulled up)
		 P1OUT |= BIT4;
		 P1OUT |= BIT5;
		 break;

	default:
		 break;
	}
	
	current_dvs = new_voltage;
}

/*
 * Increase voltage from 1 step
 */
void increase_voltage(void)
{
	if (current_dvs < 4) {
	  set_voltage(current_dvs+1);
	}
}

/*
 * Decrease voltage from one step
 */
void decrease_voltage(void)
{
	if (current_dvs > 0) {
		set_voltage(current_dvs-1);
	}
}

/*
 * Return current voltage step:
 *  1 : 1.9V
 * 	2 : 2.1V
 * 	3 : 2.7V
 * 	4 : 3.3V
 */
int get_voltage(void)
{
	return current_dvs;
}

