#include <htc.h>
//#include <pic16lf1824.h>
#include "receiver.h"
#include "hardware_config.h"
//#include "RF_settings.h"
#include <pic.h>

extern enum state_type State;
unsigned char rec_vect[8];
int rec_i;
unsigned int out;
unsigned char temp;             //global declared to reduce latency
extern unsigned char STEPCNT;   //Needed to count 1ms, used in ISR

unsigned short Receive_Packet()
{
    
    while(DATA_IN==1); //wait first descent slope
    __delay_us(200);    //could be improved using timers 
    
    for(rec_i=1;rec_i<8;rec_i++)
    {
        TMR0=32;
        STEPCNT=0;
        rec_vect[rec_i]=DATA_IN;
        // __delay_ms(1);
        while(!STEPCNT);
        STEPCNT=0;
        
    }
    rec_vect[0]=1;
    out=0;
    for(rec_i=7;rec_i>=0;rec_i--)
        out|=(rec_vect[7-rec_i])<<(rec_i);
   // TMR0=8;
    return out;
}