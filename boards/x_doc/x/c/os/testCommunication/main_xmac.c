/*
 * main_xmac.c
 *
 *  Created on: 23 avr. 2018
 *      Author: djidi
 */


/*
 * Test app to evaluate fuzzyman in a one-hop network.
 * There is NO real network stack. Packets are sent directly without
 *  even a CCA.
 */

#include <drivers/platform.h>
#include <drivers/radio/cc112x.h>
#include <tools/misc.h>
#include <tools/timer/timer.h>
#include <drivers/serial/uart/uart.h>
#include <drivers/serial/spi/spi.h>
#include <drivers/wurx/wurx.h>
#include <pt/pt.h>
#include <sched/sched.h>


#include <network/mac/ricer-wurx/ricer-wurx.h>
#include <pm/pm.h>
#include <tools/io_interrupts/io_interrupts.h>
//#include <ec_estimator/ec_estimator.h>
#include <stdlib.h>

#define SOURCE  0
//#define SINK  1u

#define SINK_MAC_ADDR   0x55u

#define DEFAULT_POLL_PERIOD 5120u   // 10s

struct pkt_t
{
    unsigned int app_seq;   // 2B
    float er;   // 4B
    float ec;   // 4B
    float eh;       // 4B
    float eb;       // 4B
    unsigned int twi;   //  2B
};
static struct pkt_t pkt;


#ifdef SINK
// Number of nodes in the network
#define NODES_COUNT 5
// Information on one node
struct app_node_t
{
    int node_id;            // Node id
    uint16 polling_period;  // Polling period
    struct pt thread;       // Sink thread in charge of polling this node
};
static struct app_node_t nodes[NODES_COUNT] = {
        {0x5Bu, 0u, 0u, 0u},
        {0x6Cu, 0u, 0u, 0u},
//      {0x6Du, 0u, 0u, 0u},
        {0x69u, 0u, 0u, 0u},
        {0x59u, 0u, 0u, 0u},
//      {0x5Au, 0u, 0u, 0u},
        {0x57u, 0u, 0u, 0u}
};

static PT_THREAD(sink_thread(void *args))
{
    uint8 addr;
    struct app_node_t *sth = (struct app_node_t*)args;

    PT_BEGIN(&(sth->thread));

    uint16 initial_backoff = rand() & 0xFFF;    // Avoiding all the thread to overlap...
    set_one_shot_timer_sleep(initial_backoff, &(sth->thread));

    for ( ;; )
    {
        WAIT_EVENT(&(sth->thread));
        rwmac_poll_node(sth->node_id, &(sth->thread));
        WAIT_EVENT(&(sth->thread));
        bool received = false;
        while (!FIFO_IS_EMPTY(rx_fifo_first, rx_fifo_last)) {
            // Received a data
            // Sending the address
            addr = *(uint8*)&(rx_fifo[rx_fifo_first].address);
            if (addr == sth->node_id) {
                received = true;
            }
            uart_send_uint((unsigned int)addr, 10u);
            uart_putchar(' ');
            memcpy(&pkt, rx_fifo[rx_fifo_first].buffer + 2, sizeof(struct pkt_t));
            // App sequence
            uart_send_uint(pkt.app_seq, 10u);
            uart_putchar(' ');
            // Residual energy
            uart_send_float(pkt.er, 10u);
            uart_putchar(' ');
            // Estimated consummed energy
            uart_send_float(pkt.ec, 10u);
            uart_putchar(' ');
            // Estimated harvested energy
            uart_send_float(pkt.eh, 10u);
            uart_putchar(' ');
            // Energy budget
            uart_send_float(pkt.eb, 10u);
            uart_putchar(' ');
            // Wake up interval
            uart_send_uint(pkt.twi, 10u);
            //
            uart_putchar('\n');
            uart_flush();

            int i;
            for (i = 0; i < NODES_COUNT; i++) {
                if (nodes[i].node_id == addr) {
                    nodes[i].polling_period = pkt.twi;
                    set_one_shot_timer_sleep(nodes[i].polling_period, &(nodes[i].thread));
                }
            }

            FIFO_INCR_PTR(rx_fifo_first, RX_FIFO_SIZE);
        }
        if (!received) {
            if (sth->polling_period > 0u) {
                set_one_shot_timer_sleep(sth->polling_period, &(sth->thread));
            } else {
                set_one_shot_timer_sleep(DEFAULT_POLL_PERIOD, &(sth->thread));
            }
        }
    }

    PT_END(&(sth->thread));
}

// Protothread that handles WuRx threads
// Total energy consummed
// The consumed energy is sent via UART when a button is pressed
float sink_ec = 0.0f;
bool send_ec = false;
static struct pt sink_ec_pt;
static PT_THREAD(sink_ec_thread(void *args))
{
    PT_BEGIN(&sink_ec_pt);

    set_periodic_timer(&sink_ec_pt, 5120u); // 10s

    for ( ;; )
    {
        WAIT_EVENT(&sink_ec_pt);

        volatile float ec = ec_estimator_get_reset(4500);

        sink_ec = sink_ec + ec; // We put some random value as the voltage. Not important.

        if (send_ec) {
            uart_putchar('\n');
            uart_putchar(0xD);
            uart_puts("Energy consummed by the sink: ");
            uart_send_float(sink_ec, 10u);
            uart_flush();
            send_ec = false;
        }
    }

    PT_END(&sink_ec_pt);
}

// When the SW1 button is pressed, the energy consummed by the sink is sent via UART
bool sw1_ISR(void)
{
    send_ec = true;
    schedule_thread(&sink_ec_pt);
    return true;
}

#elif defined SOURCE

// Application sequence number
static unsigned int app_seq = 0u;

bool gen_pkt(void)
{
    pkt.app_seq = ++app_seq;
    pkt.twi = pm_get_t_gen();
    if (pm_executed()) {
        pkt.er = pm_get_er();
        pkt.ec = pm_get_ec();
        pkt.eh = pm_get_eh();
        pkt.eb = pm_get_eb();
    } else {
        pkt.er = -1.0f;
        pkt.ec = -1.0f;
        pkt.eh = -1.0f;
        pkt.eb = -1.0f;
    }
    rwmac_push_tx_fifo((uint8*)&pkt, SINK_MAC_ADDR);

    return true;
}

#endif  // SOURCE

void main(void)
{
    msp2zigv_init();
    WDT_DISABLE;
    timer_init();
    _EINT();

#ifdef SOURCE

    pm_init();

    rwmac_init(gen_pkt);

    start_threads();

#elif defined SINK

    ec_estimator_init();    // To count the energy consumed by the sink

    // Set the interrupt handlet for the SW1 button
    io_interrupts_add_func_handler(1, 6, LOW_TO_HIGH, sw1_ISR);

    // Initializing the sink thread
    int i;
    for (i = 0; i < NODES_COUNT; i++) {
        PT_INIT(&(nodes[i].thread), sink_thread, &(nodes[i]));
        register_thread(&(nodes[i].thread));
    }

    // Initializing the sink ec estimator thead
    PT_INIT(&sink_ec_pt, sink_ec_thread, NULL);
    register_thread(&sink_ec_pt);

    rwmac_init(NULL);

    uart_init();
    uart_puts("Sink ready;");
    uart_putchar('\n');
    uart_flush();

    start_threads();

#endif
}


