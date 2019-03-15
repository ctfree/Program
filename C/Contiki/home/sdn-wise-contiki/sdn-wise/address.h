#ifndef ADDRESS_H_
#define ADDRESS_H_

#include <stdint.h>

#define ADDRESS_LENGTH  2

  typedef struct __attribute__((__packed__)) address_struct {
    uint8_t u8[ADDRESS_LENGTH];
  } address_t;

  typedef struct accepted_address_struct {
    struct accepted_address_struct* next;
    address_t address;
  } accepted_address_t;

  /* Address API. */
  uint8_t is_broadcast(address_t*);
  uint8_t is_my_address(address_t*);
  void set_broadcast_address(address_t*);
  address_t get_address_from_array(uint8_t*);
  address_t get_address_from_int(uint16_t);
  void fill_array_with_address(uint8_t*, address_t*);
  uint8_t address_cmp(address_t*, address_t*);
  void print_address(address_t*);
  void swap_addresses(address_t*,address_t*);

  /* Accepted Address API. */  
  void address_list_init(void);
  void add_accepted_address(address_t*);
  accepted_address_t* address_list_contains(address_t*);
  void purge_address_list(void);
  void print_address_list(void);
  
  /* Test API. */
  void test_address_list(void);
  

#endif /* ADDRESS_H_ */
/** @} */
