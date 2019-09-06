/*
 * Texas Instrument CC112X radio chip driver
 */

#include <msp430.h>
#include <stdbool.h>
#include <drivers/serial/spi/hal_spi_rf_trxeb.h>
#include <drivers/radio/cc112x.h>
#include <tools/timer/timer.h>
#include <tools/io_interrupts/io_interrupts.h>
#include <config.h>
#include <sched/sched.h>
#include <stdint.h>
// CCA used ?
static bool _cca_used = true;
// CRC used ?
static bool _crc_used = true;
// Interrupt status
static uint8 _it_state = 0x0;
// Is in WUB mode ?
static bool _wub_mode = false;
// Is in continuous RX state
static bool _is_ctn_rx = false;
// Thread to schedule when a packet is received in continuous RX state
static struct pt* _ctn_rx_thr = NULL;

// Interrupt cause
#define IT_NO_FAILURE       0b00000000
#define IT_RX_TIMEOUT       0b00000001
#define IT_RX_TERM_CS_PQR   0b00000010
#define IT_EWOR_SYNC_LOST   0b00000011
#define IT_RX_ERR_LENGTH    0b00000100
#define IT_RX_ERR_ADD       0b00000101
#define IT_RX_ERR_CRC       0b00000110
#define IT_TXFIFO_OVF       0b00000111
#define IT_TXFIFO_UNF       0b00001000
#define IT_RXFIFO_OVF       0b00001001
#define IT_RXFIFO_UNF       0b00001010
#define IT_TX_ERR_CCA       0b00001011
#define IT_TX_SUCCESS       0b01000000
#define IT_RX_SUCESS        0b10000000

/*
 * Interrupt handler
 */
static bool cc112x_interrupt_handler(void)
{
    uint8 regVal;

    cc112xSpiReadReg(CC112X_MARC_STATUS1, &regVal, 1);
    _it_state = regVal;

    if (_is_ctn_rx) {
        if (_it_state == IT_RX_SUCESS) {
            // Schedule the thread in charge of dealing with incoming packets
            schedule_thread(_ctn_rx_thr, true);
            // RX state
            trxSpiCmdStrobe(CC112X_SRX);

            _it_state = IT_NO_FAILURE;
            return true;    // If we are sleeping, we must wake-up
        }
        else if (_it_state == IT_RXFIFO_OVF) {
            // First we flush the RX FIFO
            trxSpiCmdStrobe(CC112X_SFRX);
            // RX state
            trxSpiCmdStrobe(CC112X_SRX);

            _it_state = IT_NO_FAILURE;

        }
        else if ((_it_state == IT_RX_ERR_CRC) || (_it_state == IT_RX_ERR_ADD) || (_it_state == IT_RX_ERR_LENGTH)) {
            _it_state = IT_NO_FAILURE;
            // RX state
            trxSpiCmdStrobe(CC112X_SRX);
        }
    }

    return false;
}

/*
 * Register settings.
 * This values comes from TI
 */
// Carrier frequency = 868.000000
// RX Filter BW = 66.67 kHz
// Deviation = 3.997803 kHz
// Manchester enable = false
// Modulation format = 2-FSK (settable)
// RX filter BW = 50.000000 kHz
// PA ramping = false
// Packet length mode = Variable
// Whitening = false
// Address config = No address check. (settable)
// Packet max length = 255
// Device address = 0 (settable)
// No status byte append
// CRC is enabled (settable)
static const registerSetting_t preferredSettings[]=
{
  {CC112X_IOCFG2,            0x14},
  {CC112X_SYNC_CFG1,         0x0B},
  {CC112X_DCFILT_CFG,        0x1C},
  {CC112X_IQIC,              0x46},
  {CC112X_CHAN_BW,           0x03},
  {CC112X_MDMCFG0,           0x05},
  {CC112X_AGC_REF,           0x20},
  {CC112X_AGC_CS_THR,        0x19},
  {CC112X_AGC_CFG1,          0xA9},
  {CC112X_AGC_CFG0,          0xCF},
  {CC112X_FS_CFG,            0x12},
  {CC112X_PA_CFG2,           0x0F},
  {CC112X_PA_CFG1,           0x56},
  {CC112X_IF_MIX_CFG,        0x00},
  {CC112X_FREQOFF_CFG,       0x22},
  {CC112X_FREQ2,             0x6C},
  {CC112X_FREQ1,             0x80},
  {CC112X_FS_DIG1,           0x00},
  {CC112X_FS_DIG0,           0x5F},
  {CC112X_FS_DIVTWO,         0x03},
  {CC112X_FS_DSM0,           0x33},
  {CC112X_FS_DVC0,           0x17},
  {CC112X_FS_PFD,            0x50},
  {CC112X_FS_PRE,            0x6E},
  {CC112X_FS_REG_DIV_CML,    0x14},
  {CC112X_FS_SPARE,          0xAC},
  {CC112X_FS_VCO0,           0xB4},
  {CC112X_XOSC5,             0x0E},
  {CC112X_XOSC3,            0xC7},
  {CC112X_XOSC1,            0x07},

  {CC112X_PKT_CFG1,          0x14},
  {CC112X_PKT_CFG0,          0x20},
  {CC112X_PKT_LEN,           0xFF},
  {CC112X_FIFO_CFG,          0x80},
  {CC112X_SETTLING_CFG,      0x03},

  // Set the RX termination timeout to 5ms
  {CC112X_WOR_EVENT0_MSB,   0x04},
  {CC112X_WOR_EVENT0_LSB,   0x00},
  {CC112X_RFEND_CFG1,       0x00},
  {CC112X_RFEND_CFG0,       0x08},
  {CC112X_WOR_CFG1,         0x08},
};

/*
 * Enable/Disable RX termination timeout
 */
#define ENABLE_TIMEOUT  do {\
                            uint8 regVal = 0x00u;   \
                            cc112xSpiWriteReg(CC112X_RFEND_CFG1, &regVal, 1);   \
                        } while (0)
#define DISABLE_TIMEOUT do {\
                            uint8 regVal = 0x0Eu;   \
                            cc112xSpiWriteReg(CC112X_RFEND_CFG1, &regVal, 1);   \
                        } while (0)

/*
 * Calibrates radio according to CC112x errata
 * This code comes from TI
 */
#define VCDAC_START_OFFSET 2
#define FS_VCO2_INDEX 0
#define FS_VCO4_INDEX 1
#define FS_CHP_INDEX 2
static void cc112x_manual_calibration(void) {

    uint8 original_fs_cal2;
    uint8 calResults_for_vcdac_start_high[3];
    uint8 calResults_for_vcdac_start_mid[3];
    uint8 marcstate;
    uint8 writeByte;

    // 1) Set VCO cap-array to 0 (FS_VCO2 = 0x00)
    writeByte = 0x00;
    cc112xSpiWriteReg(CC112X_FS_VCO2, &writeByte, 1);

    // 2) Start with high VCDAC (original VCDAC_START + 2):
    cc112xSpiReadReg(CC112X_FS_CAL2, &original_fs_cal2, 1);
    writeByte = original_fs_cal2 + VCDAC_START_OFFSET;
    cc112xSpiWriteReg(CC112X_FS_CAL2, &writeByte, 1);

    // 3) Calibrate and wait for calibration to be done
    //   (radio back in IDLE state)
    trxSpiCmdStrobe(CC112X_SCAL);

    do {
        cc112xSpiReadReg(CC112X_MARCSTATE, &marcstate, 1);
    } while (marcstate != 0x41);

    // 4) Read FS_VCO2, FS_VCO4 and FS_CHP register obtained with
    //    high VCDAC_START value
    cc112xSpiReadReg(CC112X_FS_VCO2,
                     &calResults_for_vcdac_start_high[FS_VCO2_INDEX], 1);
    cc112xSpiReadReg(CC112X_FS_VCO4,
                     &calResults_for_vcdac_start_high[FS_VCO4_INDEX], 1);
    cc112xSpiReadReg(CC112X_FS_CHP,
                     &calResults_for_vcdac_start_high[FS_CHP_INDEX], 1);

    // 5) Set VCO cap-array to 0 (FS_VCO2 = 0x00)
    writeByte = 0x00;
    cc112xSpiWriteReg(CC112X_FS_VCO2, &writeByte, 1);

    // 6) Continue with mid VCDAC (original VCDAC_START):
    writeByte = original_fs_cal2;
    cc112xSpiWriteReg(CC112X_FS_CAL2, &writeByte, 1);

    // 7) Calibrate and wait for calibration to be done
    //   (radio back in IDLE state)
    trxSpiCmdStrobe(CC112X_SCAL);

    do {
        cc112xSpiReadReg(CC112X_MARCSTATE, &marcstate, 1);
    } while (marcstate != 0x41);

    // 8) Read FS_VCO2, FS_VCO4 and FS_CHP register obtained
    //    with mid VCDAC_START value
    cc112xSpiReadReg(CC112X_FS_VCO2,
                     &calResults_for_vcdac_start_mid[FS_VCO2_INDEX], 1);
    cc112xSpiReadReg(CC112X_FS_VCO4,
                     &calResults_for_vcdac_start_mid[FS_VCO4_INDEX], 1);
    cc112xSpiReadReg(CC112X_FS_CHP,
                     &calResults_for_vcdac_start_mid[FS_CHP_INDEX], 1);

    // 9) Write back highest FS_VCO2 and corresponding FS_VCO
    //    and FS_CHP result
    if (calResults_for_vcdac_start_high[FS_VCO2_INDEX] >
        calResults_for_vcdac_start_mid[FS_VCO2_INDEX]) {
        writeByte = calResults_for_vcdac_start_high[FS_VCO2_INDEX];
        cc112xSpiWriteReg(CC112X_FS_VCO2, &writeByte, 1);
        writeByte = calResults_for_vcdac_start_high[FS_VCO4_INDEX];
        cc112xSpiWriteReg(CC112X_FS_VCO4, &writeByte, 1);
        writeByte = calResults_for_vcdac_start_high[FS_CHP_INDEX];
        cc112xSpiWriteReg(CC112X_FS_CHP, &writeByte, 1);
    } else {
        writeByte = calResults_for_vcdac_start_mid[FS_VCO2_INDEX];
        cc112xSpiWriteReg(CC112X_FS_VCO2, &writeByte, 1);
        writeByte = calResults_for_vcdac_start_mid[FS_VCO4_INDEX];
        cc112xSpiWriteReg(CC112X_FS_VCO4, &writeByte, 1);
        writeByte = calResults_for_vcdac_start_mid[FS_CHP_INDEX];
        cc112xSpiWriteReg(CC112X_FS_CHP, &writeByte, 1);
    }
}

/*
 * Init the radio
 *
 * @param clockDivider: prescalerValue - SMCLK/prescalerValue gives SCLK frequency
 *
 */
void cc112x_init(uint8 clockDivider)
{
    uint8 regVal;

    trxRfSpiInterfaceInit(clockDivider);

    // Reset radio
    trxSpiCmdStrobe(CC112X_SRES);
    _it_state = IT_NO_FAILURE;

    // Write registers to radio

    //modified by nour

    uint16 i;
    for(i = 0;
           i < (sizeof(preferredSettings)/sizeof(registerSetting_t)); i++) {
           regVal = preferredSettings[i].data;
           cc112xSpiWriteReg(preferredSettings[i].addr, &regVal, 1);
       }






    /*for(uint16 i = 0;
        i < (sizeof(preferredSettings)/sizeof(registerSetting_t)); i++) {
        regVal = preferredSettings[i].data;
        cc112xSpiWriteReg(preferredSettings[i].addr, &regVal, 1);
    }*/

    // No Preambule
    cc112x_set_preamble(NUM_PREAMBLE_0B, WRD_PREAMBLE_1);

    //
    // We use the GPIO 2 (P2.6) for the MCU_WAKEUP signal
    // Next we set the interrupt handler
    io_interrupts_add_func_handler(2, 6, LOW_TO_HIGH, cc112x_interrupt_handler);

    // Calibrate radio according to errata
    cc112x_manual_calibration();

    cc112x_data_mode();
}

/*
 * Set the modulation.
 *
 * NOTE: The CS threshold is set for each modulation scheme to value find in RFStudio.
 * The RSSI gain adjust is set to 0 in RF studio (reset value).
 *
 * @param mod: Must be MOD_2_FSK or MOD_OOK
 */
void cc112x_set_mod(uint8 mod)
{
    uint8 regVal;
    uint8 cs_thr;

    cc112xSpiReadReg(CC112X_MODCFG_DEV_E, &regVal, 1);
    regVal &= ~0x38u;
    if (mod == MOD_OOK) {
        regVal |= (3u << 3u);
    }

    cc112xSpiWriteReg(CC112X_MODCFG_DEV_E, &regVal, 1u);
    //cs_thr = 0xCEu; // -50 dBm

    //modiffied by nour
   // cs_thr = 12;//-90dbm
   // cs_thr = 0xA6u;//-90 db
 //  cs_thr = 0xE2u;//-30db
    //cs_thr = 0xECu;//-20db
   // cs_thr = 0xF6u;//-10dbm
    cs_thr = 0xFBu;//-5dbm
    //cs_thr = 0xF1u;//-15dbm
    //cs_thr = 0xEDu;//-19dbm
    cc112xSpiWriteReg(CC112X_AGC_CS_THR, &cs_thr, 1u);
}

/*
 * Set the symbol rate.
 *
 * SRATE_M is 20 bits wide given by srateM_19_16, srateM_15_8 and srateM_7_0.
 *
 * If srataE > 0, then SRATE = 32*10^6*((2^20 + SRATE_M)*2^srateE)/2^39 [ksps]
 * If srateE = 0, then SRATE = 32*10^6*(SRATE_M/2^38) [ksps]
 *
 * NOTE: srateM_19_16 and srateE are 4 bits values.
 *
 * NOTE: see datasheets p28 for more details
 */
void cc112x_set_symbol_rate(uint8 srateM_19_16, uint8 srateM_15_8, uint8 srateM_7_0, uint8 srateE)
{
    uint8 regVal;

    regVal = srateM_7_0;
    cc112xSpiWriteReg(CC112X_SYMBOL_RATE0, &regVal, 1u);

    regVal = srateM_15_8;
    cc112xSpiWriteReg(CC112X_SYMBOL_RATE1, &regVal, 1u);

    regVal = srateM_19_16 | (srateE << 4u);
    cc112xSpiWriteReg(CC112X_SYMBOL_RATE2, &regVal, 1u);
}

/*
 * Set the output power.
 *
 * Output Power = (power_ramp + 1)/2 - 18 [dBm]
 *
 * power_ramp must be in the range [3,64]
 */
void cc112x_set_output_power(uint8 power_ramp)
{
    uint8 regVal;
    cc112xSpiReadReg(CC112X_PA_CFG2, &regVal, 1u);
    regVal = (regVal & 0xC0u) + power_ramp;
    cc112xSpiWriteReg(CC112X_PA_CFG2, &regVal, 1u);
}

/*
 * Set the preamble.
 *
 * @param num: size of the preamble, must be one of the NUM_PREAMBLE_XX macros
 * @param wrd: "shape" of the preamble, must be one of the WRD_PREAMBLE_X macros
 */
void cc112x_set_preamble(uint8 num, uint8 wrd)
{
    uint8 regVal;

    regVal = wrd | (num << 2);
    cc112xSpiWriteReg(CC112X_PREAMBLE_CFG1, &regVal, 1u);
}

/*
 * Set the sync word mode
 *
 * @param mode: must be SYNC_MODE_XX
 *
 */
void cc112x_set_sync_mode(uint8 mode)
{
    uint8 regVal;
    cc112xSpiReadReg(CC112X_SYNC_CFG0, &regVal, 1u);
    regVal = (regVal & 0xE3) | (mode << 2);
    cc112xSpiWriteReg(CC112X_SYNC_CFG0, &regVal, 1u);
}

/*
 * Enable/Disbale address filtering.
 *
 * @param mode: must be one of the ADDR_CHECK_X
 * @param addr: My address. Used only if address filtering is enabled.
 */
void cc112x_set_addr_check(uint8 mode, uint8 addr)
{
    uint8 regVal;
    cc112xSpiReadReg(CC112X_PKT_CFG1, &regVal, 1u);
    regVal = (regVal & 0xCFu) + (mode << 4);
    cc112xSpiWriteReg(CC112X_PKT_CFG1, &regVal, 1u);
    if (mode != ADDR_CHK_NO) {
        regVal = addr;
        cc112xSpiWriteReg(CC112X_DEV_ADDR, &regVal, 1u);
    }
}

/*
 * Enable/Disable CRC
 *
 * NOTE: if CRC is switched from OFF to ON, the RX FIFO will be flushed
 *
 * @param mode: must be CRC_XX macros
 */
void cc112x_set_crc(uint8 mode)
{
    uint8 regVal;

    cc112xSpiReadReg(CC112X_PKT_CFG1, &regVal, 1u);
    regVal = (regVal & 0xF3u) | (mode << 2);
    cc112xSpiWriteReg(CC112X_PKT_CFG1, &regVal, 1u);

    cc112xSpiReadReg(CC112X_FIFO_CFG, &regVal, 1u);
    if (mode == CRC_DIS) {
        regVal = regVal & 0x7Fu;
    } else {
        regVal = regVal | 0x80u;
    }
    cc112xSpiWriteReg(CC112X_FIFO_CFG, &regVal, 1u);

    if (mode == CRC_DIS) {
        _crc_used = false;
    } else {
        if (!_crc_used) {
            trxSpiCmdStrobe(CC112X_SFRX);
        }
        _crc_used = true;
    }
}

/*
 * Set CCA mode
 *
 * @param mode: Must be one of CCA_NO/CCA_RSSI/CCA_RX/CCA_RSSI_RX
 */
void cc112x_set_cca(uint8 mode)
{
    uint8 regVal;

    cc112xSpiReadReg(CC112X_PKT_CFG2, &regVal, 1u);
    regVal = (regVal & 0xE3u) | (mode << 2);
    cc112xSpiWriteReg(CC112X_PKT_CFG2, &regVal, 1u);

    if (mode != CCA_NO) {
        _cca_used = true;
        //added by nour
       // trxSpiCmdStrobe(CC112X_SIDLE);
    } else {
        _cca_used = false;
    }
}

/*
 * Set the RX termination timeout.
 *
 * See userguide of CC112X p87
 */
void cc112x_set_rx_timeout(uint16 timeout)
{
    uint8 timeout_lsb = timeout & 0xFFu;
    uint8 timeout_msb = (timeout >> 8u) & 0xFFu;

    cc112xSpiWriteReg(CC112X_WOR_EVENT0_MSB, &timeout_msb, 1u);
    cc112xSpiWriteReg(CC112X_WOR_EVENT0_LSB, &timeout_lsb, 1u);
}

/*
 * Receive a packet.
 *
 * The packet format is as follows:
 *               |-------------------------------------------------------------------|
 *               |           |           |           |           |         |         |
 *               | Length    | Address   |  Address  | Data 0    | ....... |Data N   |
 *               |           |   DST     |    SRC    |           |         |         |
 *               |-------------------------------------------------------------------|
 *
 * @param buffer: where to put the received data
 * @param length: will be set to the length of the data payload (not including the length and the address)
 * @param address: will be set to the sender address
 * @param timeout: The time during which we wait for packets. 0 if no timeout. The accurate timer of the timer module is used.
 *  See the documentation of this module for details about the time unit.
 *
 * Returns RXPKT_SUCCESS/RXPKT_CRC_ERR/RXPKT_TIMEOUT/RXPKT_FIRO_ERR/RXPKT_LENGTH_ERR/RXPKT_ADDR_FAILED/RXPKT_UNEXCP depending on the outcome
 *
 * When this function returns, the radio will be in IDLE mode.
 */
int cc112x_rx_pkt(uint8* buffer, uint8 *length, uint8 *address, bool timeout)
{
    uint8 rxBytes, foo;

    if (_is_ctn_rx) {
        return RXPKT_UNEXCP;
    }

    // First we flush the RX FIFO
    trxSpiCmdStrobe(CC112X_SFRX);

    // Checking for errors
    if (_it_state != IT_NO_FAILURE) {
        return RXPKT_UNEXCP;
    }

    // Switch to RX
    trxSpiCmdStrobe(CC112X_SRX);

    //reset_one_shot_timer();
    // Set a timeout if required
    //if (timeout != 0) {
    //  set_one_shot_timer(timeout);
    //}

    if (timeout) {
        ENABLE_TIMEOUT;
    } else {
        DISABLE_TIMEOUT;
    }

    //while ((_it_state == IT_NO_FAILURE) && (!has_one_shot_timer_expired()));
    while (_it_state == IT_NO_FAILURE);


    // Timeout ?
    //if (timeout != 0u) {
    //  if (has_one_shot_timer_expired()) {
            // Timeout and no packet was received.
    //      trxSpiCmdStrobe(CC112X_SIDLE);
    //      return RXPKT_TIMEOUT;
    //  }
    //}

    // Check for errors
    if (_it_state == IT_RX_ERR_LENGTH) {
        trxSpiCmdStrobe(CC112X_SIDLE);
        _it_state = IT_NO_FAILURE;
        return RXPKT_LENGTH_ERR;
    } else if (_it_state == IT_RX_ERR_ADD) {
        trxSpiCmdStrobe(CC112X_SIDLE);
        _it_state = IT_NO_FAILURE;
        return RXPKT_ADDR_FAILED;
    } else if (_it_state == IT_RX_ERR_CRC) {
        trxSpiCmdStrobe(CC112X_SIDLE);
        _it_state = IT_NO_FAILURE;
        return RXPKT_CRC_ERR;
    } else if (_it_state == IT_RX_TIMEOUT) {
        _it_state = IT_NO_FAILURE;
        return RXPKT_TIMEOUT;
    }

    if ((_it_state == IT_RXFIFO_OVF) || (_it_state == IT_RXFIFO_UNF)) {
        trxSpiCmdStrobe(CC112X_SFRX);
        _it_state = IT_NO_FAILURE;
        return RXPKT_FIFO_ERR;
    } else if (_it_state != IT_RX_SUCESS) {
        trxSpiCmdStrobe(CC112X_SIDLE);
        return RXPKT_UNEXCP;
    }

    // If we are here, then we successfully received a packet
    // Read number of bytes in RX FIFO
    cc112xSpiReadReg(CC112X_NUM_RXBYTES, &rxBytes, 1);
    if (rxBytes < 2) {
        //trxSpiCmdStrobe(CC112X_SIDLE);
        return RXPKT_UNEXCP;
    }
    // We read the data from the RX fifo
    cc112xSpiReadRxFifo(length, 1);
    *length -= 2; // Addresses is accounted on the physical layer but not on the MAC layer
    cc112xSpiReadRxFifo(&foo, 1);   // My address///
    cc112xSpiReadRxFifo(address, 1);    // Sender address
    if (rxBytes < *length+2) {
        //trxSpiCmdStrobe(CC112X_SIDLE);
        return RXPKT_UNEXCP;
    }
    cc112xSpiReadRxFifo(buffer, *length);

    if ((_it_state == IT_RXFIFO_OVF) || (_it_state == IT_RXFIFO_UNF)) {
        trxSpiCmdStrobe(CC112X_SFRX);
        //trxSpiCmdStrobe(CC112X_SIDLE);
        _it_state = IT_NO_FAILURE;
        return RXPKT_FIFO_ERR;
    }

    //trxSpiCmdStrobe(CC112X_SIDLE);

    _it_state = IT_NO_FAILURE;

    return RXPKT_SUCCESS;
}

/*
 * Transmit a packet.
 *
 * The packet format is as follows:
 *               |-------------------------------------------------------------------|
 *               |           |           |           |           |         |         |
 *               | Length    | Address   |  Address  | Data 0    | ....... |Data N   |
 *               |           |   DST     |    SRC    |           |         |         |
 *               |-------------------------------------------------------------------|
 *                                         data[0]            data[length-1]
 *
 *   @param data   : Pointer to start of the packet buffer.
 *   @param length: Length of the payload, without counting the "Length" and "Address" fields.
 *
 * Returns TXPKT_SUCCESS/TXPKT_CCA_ERR/TXPKT_FIFO_ERR/TXPKT_UNEXCP/TXPKT_WRONG_MODE depending on the outcome
 *
 *  When this function returns, the radio will be in IDLE mode.
 */
int cc112x_tx_pkt(uint8 *data, uint8 length, uint8 address)
{
    uint8 length_phy, my_address = SELF_MAC_ADDRESS;

    if (_wub_mode) {
        return TXPKT_WRONG_MODE;
    }

    _is_ctn_rx = false;

    // First we flush the TX FIFO
    trxSpiCmdStrobe(CC112X_SFTX);

    if (_it_state != IT_NO_FAILURE) {
        return TXPKT_UNEXCP;
    }

    // Write the length on the FIFO
    length_phy = length + 2;
    cc112xSpiWriteTxFifo(&length_phy, 1);

    // Write the destination address on the FIFO
    cc112xSpiWriteTxFifo(&address, 1);

    // Write the source address on the FIFO
    cc112xSpiWriteTxFifo(&my_address, 1);

    // Writing the data payload on the FIFO
    cc112xSpiWriteTxFifo(data, length);

    // Check for an overflow
    if ((_it_state == IT_TXFIFO_OVF) || (_it_state == IT_TXFIFO_UNF)) {
        trxSpiCmdStrobe(CC112X_SFTX);
        return TXPKT_FIFO_ERR;
    } else if  (_it_state != IT_NO_FAILURE) {
        return TXPKT_UNEXCP;
    }

    // If CCA before TX is used, we first go to RX
    if (_cca_used) {
        DISABLE_TIMEOUT;
        trxSpiCmdStrobe(CC112X_SRX);
        // Wait for the CCA to be valid.
        uint8 r;
        do {
            cc112xSpiReadReg(CC112X_RSSI0, &r, 1);
        } while (!(r & 2));
    }



    // added by nour
   // trxSpiCmdStrobe(CC112X_SIDLE);
    //cc112xSpiReadReg(CC112X_MARCSTATE, &marcState, 1);


    // TX
    trxSpiCmdStrobe(CC112X_STX);

    // Waiting for the end of the transmission
    while (_it_state == IT_NO_FAILURE);

    // End of the transmission, go to IDLE state
    //trxSpiCmdStrobe(CC112X_SIDLE);

    // Check for errors
    if ((_it_state == IT_TXFIFO_OVF) || (_it_state == IT_TXFIFO_UNF)) {
        trxSpiCmdStrobe(CC112X_SFTX);
        _it_state = IT_NO_FAILURE;
        return TXPKT_FIFO_ERR;
    } else if (_it_state == IT_TX_ERR_CCA) {
        _it_state = IT_NO_FAILURE;
        trxSpiCmdStrobe(CC112X_SIDLE);
        return TXPKT_CCA_ERR;
    } else if (_it_state != IT_TX_SUCCESS) {
        trxSpiCmdStrobe(CC112X_SIDLE);
        return TXPKT_UNEXCP;
    }

    // If we are here, everything went fine
    _it_state = IT_NO_FAILURE;

    return TXPKT_SUCCESS;
}

/*
 * Transmit a WUB.
 * Must be in WUB mode.
 * A wub contains only a 1 byte word.
 *
 * @param data: WUB payload.
 *
 * Returns TXPKT_SUCCESS/TXPKT_CCA_ERR/TXPKT_FIFO_ERR/TXPKT_UNEXCP/TXPKT_WRONG_MODE depending on the outcome
 *
 *  When this function returns, the radio will be in IDLE mode.
 */
int cc112x_tx_wub(uint8 data[])
{
    if (!_wub_mode) {
        return TXPKT_WRONG_MODE;
    }

    _is_ctn_rx = false;

    // First we flush the TX FIFO
    trxSpiCmdStrobe(CC112X_SFTX);

    if (_it_state != IT_NO_FAILURE) {
        return TXPKT_UNEXCP;
    }

    // Writing the data payload on the FIFO
    cc112xSpiWriteTxFifo(data, WUB_LENGTH);

    // Check for an overflow
    if ((_it_state == IT_TXFIFO_OVF) || (_it_state == IT_TXFIFO_UNF)) {
        trxSpiCmdStrobe(CC112X_SFTX);
        return TXPKT_FIFO_ERR;
    } else if  (_it_state != IT_NO_FAILURE) {
        return TXPKT_UNEXCP;
    }

    // If CCA before TX is used, we first go to RX
    if (_cca_used) {
        trxSpiCmdStrobe(CC112X_SRX);
        // Wait for the CCA to be valid.
        uint8 r;
        do {
            cc112xSpiReadReg(CC112X_RSSI0, &r, 1);
        } while (!(r & 2));
    }

    //TODO: go to IDLE + it_state = ?

    // TX
    trxSpiCmdStrobe(CC112X_STX);

    // Waiting for the end of the transmission
    while (_it_state == IT_NO_FAILURE);

    // End of the transmission, go to IDLE state
    //trxSpiCmdStrobe(CC112X_SIDLE);

    // Check for errors
    if ((_it_state == IT_TXFIFO_OVF) || (_it_state == IT_TXFIFO_UNF)) {
        trxSpiCmdStrobe(CC112X_SFTX);
        _it_state = IT_NO_FAILURE;
        return TXPKT_FIFO_ERR;
    } else if (_it_state == IT_TX_ERR_CCA) {
        trxSpiCmdStrobe(CC112X_SIDLE);
        _it_state = IT_NO_FAILURE;
        return TXPKT_CCA_ERR;
    } else if (_it_state != IT_TX_SUCCESS) {
        trxSpiCmdStrobe(CC112X_SIDLE);
        return TXPKT_UNEXCP;
    }

    // If we are here, everything went fine
    _it_state = IT_NO_FAILURE;

    return TXPKT_SUCCESS;
}

/*
 * Go to sleep mode
 */
void cc112x_sleep(void)
{
    _is_ctn_rx = false;

    trxSpiCmdStrobe(CC112X_SPWD);
}

/*
 * Switch to data mode.
 * This mode must be used to transmit/receive data.
 * Transmit power: 0 dBm
 * Modulation: 2-FSK
 * 32 bits sync word
 * Variable payload length
 */
void cc112x_data_mode(void)
{
    uint8 regVal;

    // Output power to the -6 (par calcul -8dbm!) dBm
  //  cc112x_set_output_power(0x0F);

    // output power to -6dbm
    //cc112x_set_output_power(0x17);

    // output power to the 14dbm nour
    //cc112x_set_output_power(0x3F);

    // output power to the -10dbm nour
   // cc112x_set_output_power(0xF);

    // output power to the 10dbm nour
        //cc112x_set_output_power(0x37);

   // cc112x_set_output_power(0x31);//7dbm

   // cc112x_set_output_power(0x2F);//6dbm

    // output power to the -11.5 dbm nour
     cc112x_set_output_power(0xC);


    // Set 2-FSK modulation
    cc112x_set_mod(MOD_2_FSK);

    // Default sync
    cc112x_set_sync_mode(SYNC_MODE_32);

    // Default CRC on RSSI
    cc112x_set_crc(CRC_EN1);

    // Variable packet length
    regVal = 0x20u;
    cc112xSpiWriteReg(CC112X_PKT_CFG0, &regVal, 1);

    // Maximum packet length
    regVal = 255u;
    cc112xSpiWriteReg(CC112X_PKT_LEN, &regVal, 1);

    // Set the symbol rate to 20 ksps
    cc112x_set_symbol_rate(0x04u, 0x7Au, 0xE1, 0x08u);


    //regVal = 0x7C; //-6 dbm

    regVal = 0x1C; // -11.5 dbm

   // regVal = 0x6C; //8.5 dbm

    cc112xSpiWriteReg(CC112X_PA_CFG0, &regVal, 1);

    _wub_mode = false;
}

/*
 * Switch to WUB mode.
 * This mode must be used to transmit WUBs.
 * Transmit power: 12.5 dBm (max)
 * Modulation: ASK/OOK
 * No sync bytes
 * Fixed payload length of 1 byte
 */
void cc112x_wub_mode(void)
{
    uint8 regVal;

    // Output power to the 12.5 dBm
    cc112x_set_output_power(0x3C);

    // output power to -6dbm
     // cc112x_set_output_power(0x17);

     // cc112x_set_output_power(0x37);//10dbm

    // output power to the 14dbm nour
    // cc112x_set_output_power(0x3F);

    // output power to the -7.5 dbm nour
     //cc112x_set_output_power(0x14);


   // cc112x_set_output_power(0x18);//-2dbm (experimentallformula)   //-5.5 theorical formula



    // Set ASK/OOK modulation
    cc112x_set_mod(MOD_OOK);

    // No Sync
    cc112x_set_sync_mode(SYNC_MODE_NO);

    // No CRC
    cc112x_set_crc(CRC_DIS);

    // Fixed length packet mode
    regVal = 0x0u;
    cc112xSpiWriteReg(CC112X_PKT_CFG0, &regVal, 1);

    // Packet length set to WUB_LENGTH byte
    regVal = WUB_LENGTH;
    cc112xSpiWriteReg(CC112X_PKT_LEN, &regVal, 1);

    // Set the symbol rate to 1 kbps
    cc112x_set_symbol_rate(0x00u, 0x62u, 0x4Eu, 0x04u);




    // edited by nour
   regVal = 0x7Eu; // with 12.5 dbm drirect wub

  //  regVal = 0x6Eu;// with 10 dbm

     // regVal = 0x26u;// with -6dbm

    //regVal = 0x46u;// with 0dbm (-1.5 dbm)

    //regVal = 0x4Eu;// with 0.5dbm

   // regVal = 0x56u;// with 5dbm

    //  regVal = 0x5Eu;// with 4.5dbm

     //regVal = 0x36u;// with -2dbm

      //regVal = 0x2Eu;// with -7.5dbm wub relay

     // regVal = 0x1Eu;// with -11.5dbm theorical data relay

    //  regVal = 0x6Eu;// with 8.5dbm theorical data Direct

   // regVal = 0x2C; //-6 dbm pour le test


    cc112xSpiWriteReg(CC112X_PA_CFG0, &regVal, 1);



    // Set the symbol rate to 5 kbps
    //cc112x_set_symbol_rate(0x04u, 0x7Au, 0xE1u, 0x06u);
    //regVal = 0x7Eu;
    //cc112xSpiWriteReg(CC112X_PA_CFG0, &regVal, 1);

    // Set the symbol rate to 10 ksps
    //cc112x_set_symbol_rate(0x04u, 0x7Au, 0xE1u, 0x07u);
    //regVal = 0x7Du;
    //cc112xSpiWriteReg(CC112X_PA_CFG0, &regVal, 1);

    _wub_mode = true;
}

/*
 * Go to the continuous RX mode. The radio is set in the RX state.
 * This function is non blocking, the radio will stay in RX state after the function returns.
 * If a packet is successfully received, the thread set using the function 'cc112x_set_ctn_thr' will be scheduled.
 * If a cc112x_tx* is called, the radio will be in idle state after the call.
 * Calling cc112x_rx_pkt() will fail.
 * To leave the continous RX state, call cc112x_sleep().
 *
 * @param rcv_thr: thread to schedule when a packet is successfully recieved.
 */
void cc112x_continuous_rx(void)
{
    if (_ctn_rx_thr == NULL) {
        return;
    }

    _is_ctn_rx = true;

    // Disabling the transceiver timer
    DISABLE_TIMEOUT;

    // Going to RX state
    //trxSpiCmdStrobe(CC112X_SRX);
    trxSpiCmdStrobe(CC112X_SRX);
}

/*
 * Set the thread that should be scheduled when a packet is successfully received in continuous RX state.
 */
void cc112x_set_ctn_thr(struct pt* ctn_rx_thr)
{
    _ctn_rx_thr = ctn_rx_thr;
}

/*
 * Read the next packet from the RX transceiver buffer.
 * Useful in continuous RX mode
 */
bool cc112x_pull_pkt_rxfifo(uint8* buffer, uint8 *length, uint8 *address)
{
    uint8 rxBytes, foo;

    // Read number of bytes in RX FIFO
    cc112xSpiReadReg(CC112X_NUM_RXBYTES, &rxBytes, 1);
    if (rxBytes == 0) {
        return false;
    }
    else if (rxBytes < 2) {
        trxSpiCmdStrobe(CC112X_SFRX);
        return false;
    }

    // We read the data from the RX fifo
    cc112xSpiReadRxFifo(length, 1);
    *length -= 2; // Addresses is accounted on the physical layer but not on the MAC layer
    cc112xSpiReadRxFifo(&foo, 1);   // My address///
    cc112xSpiReadRxFifo(address, 1);    // Sender address
    if (rxBytes < *length+2) {
        return false;
    }
    cc112xSpiReadRxFifo(buffer, *length);

    if (_it_state == IT_RXFIFO_UNF) {
        trxSpiCmdStrobe(CC112X_SFRX);
        _it_state = IT_NO_FAILURE;
        return false;
    }

    return true;
}

/*
 * Returns true if the RX fifo is empty, false otherwise.
 */
bool cc112x_rxfifo_empty(void)
{
    uint8 rxBytes;

    // Read number of bytes in RX FIFO
    cc112xSpiReadReg(CC112X_NUM_RXBYTES, &rxBytes, 1);
    if ((rxBytes > 0) && (rxBytes < 2)) {
        trxSpiCmdStrobe(CC112X_SFRX);
        return true;
    }

    return (rxBytes == 0);
}

/*
 * Go to idle mode
 */
void cc112x_idle(void)
{
    _is_ctn_rx = false;

    trxSpiCmdStrobe(CC112X_SIDLE);
}
