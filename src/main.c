#include "../include/axui.h"
#include "../include/hints.h"
#include "../include/render.h"
#include <ApplicationServices/ApplicationServices.h>
#include <pthread.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

/**
 * Decl global var screens[]
 * where screen is NSScreen.screens[i] most of the times it's going to be one

struct screen {
        int x;
        int y;

        int w;
        int h;

        struct hint hints[MAX_HINTS];
        size_t nr_hints;

        struct box boxes[MAX_BOXES];
        size_t nr_boxes;

        struct window *overlay;
};

struct window {
        NSWindow *win;

        size_t nr_hooks;
        struct drawing_hook hooks[MAX_DRAWING_HOOKS];
};

collect change to a window in hooks via some sort of `window_register_draw_hook`

later when commiting exec all hooks

 *
 */
int main(int argc, char **argv) {
  if (!AXIsProcessTrusted()) {
    printf(
        "Accessibility permissions not granted. Requesting permissions...\n");
    CFDictionaryRef options = NULL;
    AXIsProcessTrustedWithOptions(options);
    return 1;
  }
  /* if (argc < 2) { */
  /*   printf("ERROR: Provide PID\n"); */
  /*   return 1; */
  /* } */
  /**/
  /* size_t count = 0; */
  /* axui_meta *list = axui_list_from_pid_window(argv[1], &count); */
  /**/
  /* for (size_t i = 0; i < count; i++) { */
  /*   if (list[i].content != NULL) { */
  /*     printf("Try %s\n", list[i].content); */
  /*     hint_render_at(list[i].pox_x, list[i].pox_y, list[i].content); */
  /*     break; */
  /*   } */
  /* } */

  render_start();

  return 0;
}
