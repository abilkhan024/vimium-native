#include "../include/find_elements.h"
#include <ApplicationServices/ApplicationServices.h>
#include <stdio.h>

int main() {
  if (!AXIsProcessTrusted()) {
    printf(
        "Accessibility permissions not granted. Requesting permissions...\n");
    CFDictionaryRef options = NULL;
    AXIsProcessTrustedWithOptions(options);
    return 1;
  }

  current_window();

  return 0;
}
