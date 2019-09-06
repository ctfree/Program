/* 
 * File:   RX_MAIN.c
 * Author: Rajeev Piyare
 * Improved version with correct address decoding
 * Created on April 13 2018
 */

#include <htc.h>
#include "hardware_config.h"
#include "receiver.h"
#include <pic12lf1552.h>

#define _XTAL_FREQ 2000000
#define PACKET_SIZE 2

#define ADDRESS     0xA500  //FIRST 2 BIT MUST BE 10

#define ATS 0xA500

#define RTS  0xA501


#define WUPSIG      RA0 = 1;__delay_ms(10);RA0 = 0; //Interrupt PIN to MSP430

unsigned char bitnr;
unsigned char bytenr;
unsigned char dataPacket[10];
unsigned char STEPCNT; 
enum state_type State;
int count;

static void interrupt int0()
{    
    if (( RFINTF ) && (State==IDLE)){
      RFINTF = 0;
      State = RECEIVE;
    }
    else if (( RFINTF ) && (State!=IDLE)){
        RFINTF = 0;
        State = IDLE;
    }
    if ( TMR0IF ){
        TMR0IF = 0;
        STEPCNT=1;
    }
    if ( IOCAF1 ){
        IOCAF1 = 0;
    }
}

void main(){
    board_init();
    unsigned short address_received;
    TRISA0 = 0;     
    GIE = 1;
    PEIE=1;
    State=IDLE;
    IOCIE=1;

while(1) {    
    switch(State)
    {
        case IDLE: 
            SLEEP();
            break;
        case SEND:
            State=IDLE;
            break;
        case RECEIVE:
            address_received=Receive_Packet();
            
            
                if ((address_received ==  RTS) || (address_received == ATS) ){
                    WUPSIG 
                   //if ((address_received == ADDRESS| RTS) || (address_received == ADDRESS| ATS) )
                }
                else State=IDLE;
            break;
        default: State=IDLE; break;
    }
}
    
}