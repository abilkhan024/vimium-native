#include <ApplicationServices/ApplicationServices.h>
#include <CoreFoundation/CFArray.h>
#include <CoreFoundation/CoreFoundation.h>
#include <CoreGraphics/CGWindow.h>
#include <CoreGraphics/CoreGraphics.h>
#include <stddef.h>
#include <stdio.h>
#include <stdlib.h>

/*
AXUIElementRef *select_nested_axui_els(jXUIElementRef win, size_t *count) {
  *count = 0;
  CFTypeRef children_ref = NULL;
  if (AXUIElementCopyAttributeValue(win, kAXChildrenAttribute, &children_ref) !=
      kAXErrorSuccess) {
    return NULL;
  }

  CFArrayRef children = (CFArrayRef)children_ref;
  CFIndex child_count = CFArrayGetCount(children);
  if (child_count == 0) {
    CFRelease(children);
    return NULL;
  }

printf("Asking bytes for malloc %lu\n", child_count * sizeof(AXUIElementRef));
  AXUIElementRef *els = malloc(child_count * sizeof(rXUIElementRef));
  for (CFIndex i = 0; i < child_count; i++) {
    AXUIElementRef child = (AXUIElementRef)CFArrayGetValueAtIndex(children, i);
    els[*count] = child;
    (*count)++;

    size_t subCount = 0;
    AXUIElementRef *subElements = select_nested_axui_els(child, &subCount);
    if (subElements) {
printf("Asking bytes for realloc %lu\n",       (*count + subCount) *
sizeof(AXUIElementRef)); els = realloc(els, (*count + subCount) *
sizeof(AXUIElementRef)); for (size_t j = 0; j < subCount; j++) { els[*count + j]
= subElements[j];
      }
      (*count) += subCount;
      free(subElements);
    }
  }

  CFRelease(children);
  return els;
}
*/

char *axui_to_string(AXUIElementRef el) {
  CFTypeRef roleRef = NULL, titleRef = NULL;
  char *roleStr = NULL, *titleStr = NULL;

  if (AXUIElementCopyAttributeValue(el, kAXRoleAttribute, &roleRef) ==
      kAXErrorSuccess) {
    roleStr = (char *)CFStringGetCStringPtr((CFStringRef)roleRef,
                                            kCFStringEncodingUTF8);
  }
  if (AXUIElementCopyAttributeValue(el, kAXTitleAttribute, &titleRef) ==
      kAXErrorSuccess) {
    titleStr = (char *)CFStringGetCStringPtr((CFStringRef)titleRef,
                                             kCFStringEncodingUTF8);
  }

  size_t len =
      (roleStr ? strlen(roleStr) : 0) + (titleStr ? strlen(titleStr) : 0) + 5;
  char *result = malloc(len);
  snprintf(result, len, "%s, %s", roleStr ? roleStr : "",
           titleStr ? titleStr : "");

  if (roleRef)
    CFRelease(roleRef);
  if (titleRef)
    CFRelease(titleRef);

  return result;
}

/**
 * @param els_count Expects to be set to 0 when calling on the window as parent
 * @param els Chunk that will be populated by leaf elements until limit is
 * reached, caller must ensure that there is space for at least `limit` elements
 */
void select_leaf_els(AXUIElementRef node, size_t *els_count,
                     AXUIElementRef *els, size_t *limit) {
  if (*els_count >= *limit) {
    return;
  }
  CFTypeRef children_ref = NULL;
  if (AXUIElementCopyAttributeValue(node, kAXChildrenAttribute,
                                    &children_ref) != kAXErrorSuccess) {
    return;
  }

  CFArrayRef children = (CFArrayRef)children_ref;
  CFIndex child_count = CFArrayGetCount(children);

  if (child_count == 0) {
    els[*els_count] = node;
    (*els_count)++;
    return CFRelease(children);
  }
  for (CFIndex i = 0; i < child_count; i++) {
    AXUIElementRef child = (AXUIElementRef)CFArrayGetValueAtIndex(children, i);
    select_leaf_els(child, els_count, els, limit);
  }
}

AXUIElementRef *select_axui_els(pid_t pid, size_t *count) {
  *count = 0;

  AXUIElementRef appElement = AXUIElementCreateApplication(pid);
  if (appElement == NULL) {
    printf("Failed to create AXUIElement for PID %d\n", pid);
    return NULL;
  }

  // Get all windows
  CFTypeRef windowsRef = NULL;
  int result = AXUIElementCopyAttributeValue(appElement, kAXWindowsAttribute,
                                             &windowsRef);
  if (result != kAXErrorSuccess) {
    printf("Failed to get windows for application PID: %d, with %d\n", pid,
           result);
    CFRelease(appElement);
    return NULL;
  }

  CFArrayRef windows = (CFArrayRef)windowsRef;
  CFIndex win_count = CFArrayGetCount(windows);
  printf("PID: %d, has %ld windows\n", pid, (long)win_count);

  size_t total_els = 0;
  AXUIElementRef *allElements = NULL;

  for (CFIndex i = 0; i < win_count; i++) {
    AXUIElementRef window = (AXUIElementRef)CFArrayGetValueAtIndex(windows, i);
    size_t els_count = 0;
    size_t els_limit = 2000;
    AXUIElementRef *els = malloc(sizeof(AXUIElementRef) * els_limit);
    select_leaf_els(window, &els_count, els, &els_limit);
    total_els += els_count;
    for (size_t i = 0; i < els_count; i++) {
      char *desc = axui_to_string(els[i]);
      printf("Element %zu: '%s'\n", i, desc);
      free(desc);
    }
    break;
  }

  *count = total_els;
  CFRelease(windows);
  CFRelease(appElement);
  printf("PID: %d, elements %zu\n", pid, total_els);

  return allElements;
}

int current_window() {
  /*
  CFArrayRef apps = CGWindowListCopyWindowInfo(kCGWindowListOptionOnScreenOnly,
                                               kCGNullWindowID);
  if (apps == NULL) {
    perror("ERROR: Failed to get front most application\n");
    return 1;
  }
  CFIndex count = CFArrayGetCount(apps);

  if (count == 0) {
    perror("No active windows found.\n");
    CFRelease(apps);
    return 1;
  }
   */

  /* CFDictionaryRef windowInfo = */
  /*     (CFDictionaryRef)CFArrayGetValueAtIndex(apps, i); */
  size_t pid = 37587;
  size_t els_count = 0;
  printf("%zu %zu\n", pid, els_count);
  AXUIElementRef *elements = select_axui_els(pid, &els_count);

  /*
  for (CFIndex i = 0; i < count; i++) {
    CFDictionaryRef windowInfo =
        (CFDictionaryRef)CFArrayGetValueAtIndex(apps, i);
    CFNumberRef pidRef = CFDictionaryGetValue(windowInfo, kCGWindowOwnerPID);
    if (!pidRef)
      continue;

    pid_t pid;
    CFNumberGetValue(pidRef, kCFNumberIntType, &pid);

    size_t els_count = 0;

    printf("%d %zu\n", pid, els_count);
    AXUIElementRef *elements = select_axui_els(pid, &els_count);

    if (elements != NULL) {
      printf("Found %zu interactive elements in PID %d:\n", els_count, pid);
      for (size_t j = 0; j < els_count && j < 10; j++) {
        char *desc = axui_to_string(elements[j]);
        if (desc != NULL) {
          printf("- %s\n", desc);
          free(desc);
        }
      }
      free(elements);
    } else {
      printf("Elements are NULL");
    }
    break; // Only process the first frontmost app
  }

  CFRelease(apps);

  */

  return 0;
}
