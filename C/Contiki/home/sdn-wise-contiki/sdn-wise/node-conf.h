#ifndef NODE_CONF_H_
#define NODE_CONF_H_

#include <stdint.h>
#include "address.h"

  typedef struct node_conf_struct {
    uint8_t my_net;
    address_t my_address;
    uint8_t packet_ttl;
    uint8_t rssi_min;
    uint16_t beacon_period;
    uint16_t report_period;
    uint16_t rule_ttl; 
    address_t nxh_vs_sink;
    uint8_t hops_from_sink;
    uint8_t rssi_from_sink;  
    address_t sink_address;
    uint8_t is_active;
    uint8_t requests_count;
  } node_conf_t;

  extern node_conf_t conf;

  /* Node Configuration API. */
  void node_conf_init(void);
  void print_node_conf(void);
#endif /* NODE_CONF */
/** @} */
