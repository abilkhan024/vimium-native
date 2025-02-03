#include <ApplicationServices/ApplicationServices.h>
#include <CoreFoundation/CoreFoundation.h>
#include <CoreFoundation/CFArray.h>
#include <CoreGraphics/CGWindow.h>
#include <CoreGraphics/CoreGraphics.h>
#include <stdio.h>
#include <stdlib.h>

AXUIElementRef *select_nested_axui_els(AXUIElementRef element, size_t *count) {
  *count = 0;
  CFTypeRef childrenRef = NULL;
  if (AXUIElementCopyAttributeValue(element, kAXChildrenAttribute,
                                    &childrenRef) != kAXErrorSuccess) {
    return NULL;
  }

  CFArrayRef children = (CFArrayRef)childrenRef;
  CFIndex childCount = CFArrayGetCount(children);
  if (childCount == 0) {
    CFRelease(children);
    return NULL;
  }

  AXUIElementRef *elements = malloc(childCount * sizeof(AXUIElementRef));
  for (CFIndex i = 0; i < childCount; i++) {
    AXUIElementRef child = (AXUIElementRef)CFArrayGetValueAtIndex(children, i);
    elements[*count] = child;
    (*count)++;

    size_t subCount = 0;
    AXUIElementRef *subElements = select_nested_axui_els(child, &subCount);
    if (subElements) {
      elements =
          realloc(elements, (*count + subCount) * sizeof(AXUIElementRef));
      for (size_t j = 0; j < subCount; j++) {
        elements[*count + j] = subElements[j];
      }
      (*count) += subCount;
      free(subElements);
    }
  }

  CFRelease(children);
  return elements;
}

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

AXUIElementRef *select_axui_els(pid_t pid, size_t *count) {
  *count = 0;

  // Create accessibility object for application
  AXUIElementRef appElement = AXUIElementCreateApplication(pid);
  if (!appElement) {
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
  CFIndex windowCount = CFArrayGetCount(windows);
  printf("%ld windows count %d\n", (long)windowCount, pid);

  // Collect all interactive elements
  size_t totalElements = 0;
  AXUIElementRef *allElements = NULL;

  for (CFIndex i = 0; i < windowCount; i++) {
    AXUIElementRef window = (AXUIElementRef)CFArrayGetValueAtIndex(windows, i);
    size_t windowElementsCount = 0;
    AXUIElementRef *windowElements =
        select_nested_axui_els(window, &windowElementsCount);

    if (windowElements) {
      allElements = realloc(allElements, (totalElements + windowElementsCount) *
                                             sizeof(AXUIElementRef));
      for (size_t j = 0; j < windowElementsCount; j++) {
        allElements[totalElements + j] = windowElements[j];
      }
      totalElements += windowElementsCount;
      free(windowElements);
    }
  }

  *count = totalElements;
  CFRelease(windows);
  CFRelease(appElement);

  return allElements;
}


// Function to get PID of an app by bundle identifier
pid_t getPidForBundleID(const char* bundleID) {
    CFStringRef cfBundleID = CFStringCreateWithCString(NULL, bundleID, kCFStringEncodingUTF8);
    if (!cfBundleID) return 0;

    // Get a list of running applications
    CFArrayRef appList = CFArrayCreateMutable(NULL, 0, &kCFTypeArrayCallBacks);
    if (!appList) {
        CFRelease(cfBundleID);
        return 0;
    }

    // Fetch all running applications
    CFArrayRef runningApps = LSCopyApplicationArrayInFrontToBackOrder();
    if (!runningApps) {
        CFRelease(cfBundleID);
        CFRelease(appList);
        return 0;
    }

    /* CFIndex count = CFArrayGetCount(runningApps); */
    /* pid_t targetPid = 0; */
    /**/
    /* for (CFIndex i = 0; i < count; i++) { */
    /*     LSApplicationRecordRef appRecord = (LSApplicationRecordRef)CFArrayGetValueAtIndex(runningApps, i); */
    /*     CFStringRef appBundleID = LSApplicationRecordGetBundleIdentifier(appRecord); */
    /**/
    /*     if (appBundleID && CFStringCompare(appBundleID, cfBundleID, 0) == kCFCompareEqualTo) { */
    /*         targetPid = LSApplicationRecordGetProcessID(appRecord); */
    /*         break; */
    /*     } */
    /* } */
    /**/
    /* CFRelease(runningApps); */
    /* CFRelease(cfBundleID); */
    /* return targetPid; */
}
int current_window() {
  /* getPidForBundl */

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
