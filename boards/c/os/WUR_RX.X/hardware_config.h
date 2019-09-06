/* 
 * File: hardware_config.h
 * Author: Antonino Faraone
 * Comments: HW configuration File For transmitter only. Please accordingly modify to 
 * implement Reciver
 * Revision history: 7 March 2018
 */

#ifndef HW_CONFIG
#define	HW_CONFIG
#include <xc.h>  

#pragma config WDTE = OFF       // Watchdog Timer Enable (WDT disabled)
#pragma config FOSC = INTOSC    // Oscillator Selection (INTOSC oscillator: I/O function on CLKIN pin)
#pragma config PWRTE = ON       // Power-up Timer Enable (PWRT disabled)
#pragma config MCLRE = OFF      // MCLR Pin Function Select (MCLR/VPP pin function is MCLR)
#pragma config CP = OFF         // Flash Program Memory Code Protection (Program memory code protection is disabled)
//#pragma config CPD = OFF        // Data Memory Code Protection (Data memory code protection is disabled)
#pragma config BOREN = OFF      // Brown-out Reset Enable (Brown-out Reset disabled)
#pragma config CLKOUTEN = OFF   // Clock Out Enable (CLKOUT function is disabled. I/O or oscillator function on the CLKOUT pin)
//#pragma config IESO = OFF       // Internal/External Switchover (Internal/External Switchover mode is disabled)
//#pragma config FCMEN = OFF      // Fail-Safe Clock Monitor Enable (Fail-Safe Clock Monitor is disabled)

// CONFIG2
#pragma config WRT = OFF        // Flash Memory Self-Write Protection (Write protection off)
//#pragma config PLLEN = OFF      // PLL Enable (4x PLL disabled)
#pragma config STVREN = ON      // Stack Overflow/Underflow Reset Enable (Stack Overflow or Underflow will cause a Reset)
#pragma config BORV = LO        // Brown-out Reset Voltage Selection (Brown-out Reset Voltage (Vbor), low trip point selected.)
#pragma config LVP = OFF        // Low-Voltage Programming Enable (High-voltage on MCLR/VPP must be used for programming)

//#define _XTAL_FREQ 8000000
#define _XTAL_FREQ 2000000

#define LED	RA0
#define DATA    RC5
#define CTRL	RC4
#define DATA_DIRECTION TRISC5
#define CTRL_DIRECTION TRISC4
#define DEBUG_DIRECTION TRISC2
#define DEBUG_PIN   RC2

//receiver
#define DATA_IN     RA4
#define RFINT       RA5
#define RFINTPinDir TRISA5
#define RFINTPinAn  ANSA5
#define DATAPinDir  TRISA4
#define DATAPinAn   ANSA4
#define RFINT_POSITIVE_EDGE IOCAP5
#define RFINT_NEGATIVE_EDGE IOCAN5
#define DATA_POSITIVE_EDGE  IOCAP4
#define DATA_NEGATIVE_EDGE  IOCAN4

#define Gie //useless
#define Peie 0x40   //useless
#define Tmr0 0x20   //useless
#define Ioc 0x08    //useless
#define RFINTF IOCAF5
#define DATAF IOCAF4

#define DATA_RATE_1K
#ifdef DATA_RATE_1K

//16us timestep, overflow 4,08 ms
#define b_1KBS 60

enum state_type {IDLE,SEND,RECEIVE};

#endif
/*******************************************************************************
 * @fn      board_init
 *
 * @brief   initialises the clock to a value of 8MHz, initialize Pin direction
 *
 * @param   none
 *
 * @return  none
 ******************************************************************************/
void board_init();


/*******************************************************************************
 * @fn      tmr0_init
 *
 * @brief   Inizialize Timer 0 as Counter Mode
 *
 * @param   none
 *
 * @return  none
 ******************************************************************************/
void tmr0_init();


#endif	/* XC_HEADER_TEMPLATE_H */

