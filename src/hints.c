#include "../include/hints.h"
#include <stdio.h>

int hint_render_at(int x, int y, char *content) {
  printf("'%s', at %d x %d\n", content, x, y);
  return 0;
};
