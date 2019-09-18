/*
 * RCUP V4 drivers for PowWow
 */

#include <drivers/rcup/rcup_v4/rcup_v4.h>
#include <drivers/serial/i2c/i2c.h>
#include <msp430.h>

/*
 * INA3221 macros
 */
#define INA3221_RDADDR 0b10000001
#define INA3221_WRADDR 0b10000000
#define INA3221_ADDR 0x40

/*
 * Registers
 */
#define INA3221_CONFIGURATION 0x00
  #define RST (1<<15)
  #define CH1_EN (1<<14)
  #define CH2_EN (1<<13)
  #define CH3_EN (1<<12)
  #define AVG2 (1<<11)
  #define AVG1 (1<<10)
  #define AVG0 (1<<9)
  #define VBUSCT2 (1<<8)
  #define VBUSCT1 (1<<7)
  #define VBUSCT0 (1<<6)
  #define VSHCT2 (1<<5)
  #define VSHCT1 (1<<4)
  #define VSHCT0 (1<<3)
  #define MODE3 (1<<2)
  #define MODE2 (1<<1)
  #define MODE1 (1<<0)

#define INA3221_C1_SHUNT 0x01
#define INA3221_C1_BUS 0x02
#define INA3221_C2_SHUNT 0x03
#define INA3221_C2_BUS 0x04
#define INA3221_C3_SHUNT 0x05
#define INA3221_C3_BUS 0x06

#define INA3221_MASK_ENABLE 0x0F
  #define SCC1 (1<<14)
  #define SCC2 (1<<13)
  #define SCC3 (1<<12)
  #define WEN  (1<<11)
  #define CEN  (1<<10)
  #define CF1  (1<<9)
  #define CF2  (1<<8)
  #define CF3  (1<<7)
  #define SF   (1<<6)
  #define WF1  (1<<5)
  #define WF2  (1<<4)
  #define WF3  (1<<3)
  #define PVF  (1<<2)
  #define TCF  (1<<1)
  #define CVRF (1<<0)

#define INA3221_MANUFACTURER 0xFE
#define INA3221_DIE 0xFF

/*
 * Initialize RCUP.
 * Must be called before any operations involving RCUP is done
 */
void rcup_init(void)
{
	// Pin mapping
	// 3.1 - SDA (see I2C driver)
	// 3.3 - SCL (see I2C driver)
	// 3.6 - IT (in)
	// 3.7 - IO (out)
	P3DIR &= ~BIT6;
	P3DIR |= BIT7;
	// Power off INA
	P3OUT &= ~BIT7;
}

static int set_register(char INA_register, unsigned int value)
{
	uart_to_i2c();

	I2CSA = INA3221_ADDR; //INA address
	U0CTL |= MST;       //master mode
	I2CTCTL |= I2CTRX;    //transmit
	I2CNDAT = 3;          //send 3 bytes (register pointer | MSB | LSB)
	U0CTL |= I2CEN;     //enable I2C module
	I2CIFG = 0;           //clear flags

	I2CTCTL |= I2CSTT+I2CSTP; //start and autostop

	I2CDRB = INA_register; //data1 : address register

	while (((I2CIFG&TXRDYIFG) == 0)); //wait for end of transmission
    
	if ((I2CIFG&NACKIFG) != 0) {
		// No ACK
		goto set_reg_err_end;
	}
  
	I2CDRB=((value / 256) & 0xFF); //data2 : register value MSB
    
	while (((I2CIFG&TXRDYIFG) == 0)) {
		if ((I2CIFG&NACKIFG) != 0) {
			// No ACK
			goto set_reg_err_end;
		}
	}
    
	if ((I2CIFG&NACKIFG) != 0) {
		// No ACK
		goto set_reg_err_end;
	}
  
	I2CDRB= (value & 0xFF); //data1 : register value LSB
    
	while (((I2CTCTL&I2CSTP) != 0)); //wait for end of transmission

	i2c_to_uart();
	return RCUP_SUCCESS;

set_reg_err_end:
	i2c_to_uart();
	return RCUP_ERROR;
}

static int get_register(char INA_register)
{
	unsigned int received1, received2;
	unsigned int i;

	uart_to_i2c();

	I2CSA = INA3221_ADDR; //INA address
	U0CTL |= MST;       //master mode
	I2CTCTL |= I2CTRX;    //transmit
	I2CNDAT = 1;          //only one byte (register pointer)
	U0CTL |= I2CEN;     //enable I2C module
	I2CIFG = 0;           //clear flags

	I2CTCTL |= I2CSTT+I2CSTP; //start and autostop

	I2CDRB = INA_register; //data1 : address register manufacturer ID
	
	while (((I2CDCTL&I2CBUSY) != 0)); //wait for end of transmission
    
	if ((I2CIFG&NACKIFG) != 0) { //if no acknoledge
		i2c_to_uart();
		return RCUP_ERROR;
	}
  
	//else INA3221 answered
	I2CTCTL &= ~I2CTRX; //receive mode
	U0CTL |= MST; //MSP still master
	I2CIFG&= ~NACKIFG; //clear flags
	I2CNDAT=2; //2 bytes will be recived from INA (16bit register)

	I2CTCTL|=I2CSTT+I2CSTP; //start transnmission with auto stop
   
	i = 1;
	// wait for reception of 1st byte
	while (((I2CIFG&RXRDYIFG) == 0) && (i < 40000)) {
	   	i++;
	}
	received1 = I2CDRB;

	i = 1;
	while (((I2CIFG&RXRDYIFG) == 0) && ( i < 40000)) {
		 //wait for reception of 2bd byte
	   	i++;
	}
	received2 = I2CDRB;
  
	i2c_to_uart();

	return (received1*256 + received2);
}

/*
 * Read the current VStore and Vin values
 *
 * Returns RCUP_ERROR or RCUP_SUCCESS depending on how it went.
 */
int rcup_read_voltages(void)
{
	int ret, v_store;

	P3OUT |= BIT7;	// Power on INA3221

	ret = set_register(INA3221_CONFIGURATION,
			CH3_EN	// Enable channel 3 (Vstore)
			| VBUSCT2 | VBUSCT1 | VBUSCT0 // Long conversion for more accuracy
			| VSHCT2 | VSHCT1 | VSHCT0
			| MODE2); // One shot
	if (ret == RCUP_ERROR) {
		goto read_volt_err_end;	
	}

	// Wait the end of the transmission
	while ((get_register(INA3221_MASK_ENABLE) & CVRF) == 0);

	v_store = get_register(INA3221_C3_BUS);
	if (v_store == RCUP_ERROR) {
		goto read_volt_err_end;
	}

	ret = set_register(INA3221_CONFIGURATION, 0);
	if (ret == RCUP_ERROR) {
		goto read_volt_err_end;
	}

	P3OUT &= ~BIT7;	// Power down INA3221
	
	return v_store;

read_volt_err_end:
	P3OUT &= BIT7;	// Power down INA3221
	return RCUP_ERROR;
}

