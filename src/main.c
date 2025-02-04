#include "../include/find_elements.h"
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

  current_window(argv[1]);

  return 0;
}
