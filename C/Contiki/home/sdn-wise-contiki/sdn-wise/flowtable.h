#ifndef FLOWTABLE_H_
#define FLOWTABLE_H_

#include "packet-buffer.h"
#include "lib/list.h"

#define MERGE_BYTES(a,b) ((a << 8) | b)
#define WINDOW_SIZE 5

  typedef enum action_type {
    NULL_TYPE,
    FORWARD_U,
    FORWARD_B,
    DROP,
    ASK,
    FUNCTION,
    SET,
    MATCH
  } action_type_t;

  typedef enum operator_location {
    NULL_LOC,
    CONST,
    PACKET,
    STATUS
  } operator_location_t;

  typedef enum operator_size {
    SIZE_1,
    SIZE_2
  } operator_size_t;

  typedef enum operator_name {
    EQUAL,
    NOT_EQUAL,
    GREATER,
    LESS,
    GREATER_OR_EQUAL,
    LESS_OR_EQUAL
  } operator_t;

  typedef enum set_name {
    ADD,
    SUB,
    DIV,
    MUL,
    MOD,
    AND,
    OR,
    XOR
  } set_operator_t;

  typedef struct window{
    struct window *next;
    operator_t operation;
    operator_size_t size;
    operator_location_t lhs_location;
    operator_location_t rhs_location;
    uint16_t lhs;
    uint16_t rhs;
  } window_t;

  typedef struct byte{
    struct byte *next;
    uint8_t value; 
  } byte_t;

  typedef struct action{
    struct action *next;
    action_type_t type;
    LIST_STRUCT(bytes);
  } action_t;

  typedef struct stats{
    uint16_t ttl;
    uint16_t count;
  } stats_t;

  typedef struct entry{
    struct entry *next;
    LIST_STRUCT(windows);
    LIST_STRUCT(actions);
    stats_t stats;
  } entry_t;

/* FlowTable API. */
  void flowtable_init(void);
  void test_flowtable(void);
  entry_t* get_entry_from_array(uint8_t*, uint16_t);
  uint8_t* get_array_from_entry(entry_t*);
  void print_flowtable(void);
  void remove_flowtable(void);
  void print_entry(entry_t*);
  uint8_t action_cmp(action_t*, action_t*);
  uint8_t window_cmp(window_t*, window_t*);
  uint8_t entry_cmp(entry_t*, entry_t*);
  void add_entry(entry_t*);
  window_t* get_window_from_array(uint8_t*);

  entry_t* create_entry(void);
  window_t* create_window(void);
  action_t* create_action(action_type_t, uint8_t*, uint8_t);
  void add_window(entry_t*, window_t*);
  void add_action(entry_t*, action_t*);

  void match_packet(packet_t*);
  int match_entry(packet_t*, entry_t*);
  int match_window(packet_t*,uint8_t* s, window_t*);
  int run_action(packet_t*, uint8_t* s, action_t*);
#endif /* FLOWTABLE_H_ */
/** @} */
