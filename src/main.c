#include "../include/find_elements.h"
#include "../include/hints.h"
#include <ApplicationServices/ApplicationServices.h>
#include <stdio.h>

int main(int argc, char **argv) {
  if (!AXIsProcessTrusted()) {
    printf(
        "Accessibility permissions not granted. Requesting permissions...\n");
    CFDictionaryRef options = NULL;
    AXIsProcessTrustedWithOptions(options);
    return 1;
  }
  if (argc < 2) {
    printf("ERROR: Provide PID\n");
    return 1;
  }

  size_t count = 0;
  axui_meta *list = axui_list_from_pid_window(argv[1], &count);

  /* for (size_t i = 0; i < count; i++) { */
    /* hint_render_at(list[i].pox_x, list[i].pox_y, list[i].role); */
  /* } */

  return 0;
}
