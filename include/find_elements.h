#include <stddef.h>

typedef struct {
  char *role;
  char *content;

  int pox_x;
  int pox_y;
} axui_meta;

axui_meta *axui_list_from_pid_window(char *pid_str, size_t *count);
