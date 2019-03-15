#ifndef NEIGHBOR_TABLE_H_
#define NEIGHBOR_TABLE_H_

#include "address.h"
#include "packet-buffer.h"

#define NEIGHBOR_LENGTH       (ADDRESS_LENGTH + 1)

  typedef struct neighbor_struct {
    struct neighbor_struct *next;
    address_t address;
    uint8_t rssi;
    uint8_t is_alive;
  } neighbor_t;

  /* Header API. */
  //void add_neighbor(address_t*, uint8_t rssi);
  void add_neighbor(address_t*, uint8_t rssi, uint8_t is_alive);
  void remove_neighbor(neighbor_t*);
  void update_topo_neighbor(void);
  void reset_isalive_neighbor(void);
  void purge_neighbor_table(void);
  void fill_payload_with_neighbors(packet_t*);
  void neighbor_table_init(void);
  void print_neighbor_table(void);
  void test_neighbor_table(void);
  neighbor_t* neighbor_table_contains(address_t*);
  uint8_t neighbor_cmp(neighbor_t*, neighbor_t*);
  address_t nearest_neighbor();
#endif /* NEIGHBOR_TABLE_H_ */
/** @} */
