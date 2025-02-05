#include "../include/axui.h"
#include "../include/sys.h"
#include <ApplicationServices/ApplicationServices.h>
#include <CoreFoundation/CFArray.h>
#include <CoreFoundation/CFBase.h>
#include <CoreFoundation/CoreFoundation.h>
#include <CoreGraphics/CGWindow.h>
#include <CoreGraphics/CoreGraphics.h>
#include <stddef.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define SPLIT ", "
const char *split = SPLIT;
const int split_len = sizeof(SPLIT);
#undef SPLIT

void axui_append_attr_val(AXUIElementRef el, CFStringRef attr, char **cur_str,
                          size_t *cur_len) {
  CFTypeRef attr_ref = NULL;
  char *attr_val = NULL;

  if (AXUIElementCopyAttributeValue(el, attr, &attr_ref) != kAXErrorSuccess) {
    return;
  }

  if (attr_ref == NULL) {
    return;
  }

  if (CFGetTypeID(attr_ref) != CFStringGetTypeID()) {
    return CFRelease(attr_ref);
  }

  const size_t max_content = 1024 * 1024;
  char buffer[max_content];
  if (!CFStringGetCString(attr_ref, buffer, max_content,
                          kCFStringEncodingUTF8)) {
    return CFRelease(attr_ref);
  }

  attr_val = buffer;
  CFRelease(attr_ref);
  if (attr_val == NULL) {
    return;
  }

  size_t attr_len = strlen(attr_val);
  if (attr_len == 0) {
    return;
  }

  bool need_split = *cur_len != 0;
  size_t new_len = *cur_len + attr_len;
  if (need_split) {
    new_len += split_len;
  }

  (*cur_str) = realloc(*cur_str, new_len);

  for (int i = 0; i < split_len - 1 && need_split; i++, (*cur_len)++) {
    (*cur_str)[*cur_len] = split[i];
  }

  for (int i = 0; i < attr_len; i++, (*cur_len)++) {
    (*cur_str)[*cur_len] = attr_val[i];
  }
}

bool axui_role_with_value_attr(char *role) {
  return (strcmp(role, "AXGroup") == 0) || (strcmp(role, "AXTabGroup") == 0) ||
         (strcmp(role, "AXRadioButton") == 0);
}

char *axui_to_string(AXUIElementRef el) {
  size_t len = 0;
  char *str = NULL;
  axui_append_attr_val(el, kAXRoleAttribute, &str, &len);
  axui_append_attr_val(el, kAXTitleAttribute, &str, &len);
  axui_append_attr_val(el, kAXLabelValueAttribute, &str, &len);
  axui_append_attr_val(el, kAXValueAttribute, &str, &len);
  axui_append_attr_val(el, kAXValueDescriptionAttribute, &str, &len);

  return str;
}

void axui_select_nested(AXUIElementRef node, AXUIElementRef *els,
                        size_t *cur_els_count, const size_t *limit,
                        CFTypeRef *children_ref_ptrs,
                        size_t *children_ref_len) {
  if (*cur_els_count >= *limit) {
    return;
  }
  CFTypeRef children_ref = NULL;
  if (AXUIElementCopyAttributeValue(node, kAXChildrenAttribute,
                                    &children_ref) != kAXErrorSuccess) {
    return;
  }

  CFArrayRef children = (CFArrayRef)children_ref;
  CFIndex child_count = CFArrayGetCount(children);

  els[*cur_els_count] = node;
  (*cur_els_count)++;

  for (CFIndex i = 0; i < child_count; i++) {
    AXUIElementRef child = (AXUIElementRef)CFArrayGetValueAtIndex(children, i);
    axui_select_nested(child, els, cur_els_count, limit, children_ref_ptrs,
                       children_ref_len);
  }

  children_ref_ptrs[(*children_ref_len)++] = children_ref;
}

axui_meta *axui_list_from_process(pid_t pid, size_t *count) {
  *count = 0;

  AXUIElementRef app = AXUIElementCreateApplication(pid);
  if (app == NULL) {
    printf("Failed to create AXUIElement for PID %d\n", pid);
    return NULL;
  }

  CFTypeRef windows_ref = NULL;
  int result =
      AXUIElementCopyAttributeValue(app, kAXWindowsAttribute, &windows_ref);
  if (result != kAXErrorSuccess) {
    printf("Failed to get windows for application PID: %d, with %d\n", pid,
           result);
    CFRelease(app);
    return NULL;
  }

  CFArrayRef windows = (CFArrayRef)windows_ref;
  CFIndex win_count = CFArrayGetCount(windows);

  size_t total_els = 0;

  const size_t els_limit =
      3000; // TODO: Don't know which value would be logical but
            // setting to just arbitrarily large value

  AXUIElementRef *els = malloc(sizeof(AXUIElementRef) * els_limit);
  size_t children_ref_ptrs_len = 0;
  CFTypeRef *children_ref_ptrs = malloc(sizeof(CFTypeRef) * els_limit);

  if (els == NULL) {
    printf("ERROR: Allocating vector for axui els");
    abort();
  }

  CFIndex i = 0; // TODO: < win_count?
  AXUIElementRef window = (AXUIElementRef)CFArrayGetValueAtIndex(windows, i);
  axui_select_nested(window, els, &total_els, &els_limit, children_ref_ptrs,
                     &children_ref_ptrs_len);
  total_els += total_els;
  axui_meta *meta_els = malloc(total_els * sizeof(axui_meta));

  for (size_t i = 0; i < total_els; i++) {
    char *role = NULL;
    size_t role_len = 0;
    axui_append_attr_val(els[i], kAXRoleAttribute, &role, &role_len);

    char *content = NULL;
    size_t content_len = 0;
    axui_append_attr_val(els[i], kAXValueAttribute, &content, &content_len);

    meta_els[i].role = role;
    meta_els[i].content = content;

    meta_els[i].pox_x = 69;
    meta_els[i].pox_y = 69;
  }

  for (size_t i = 0; i < children_ref_ptrs_len; i++) {
    CFRelease(children_ref_ptrs[i]);
  }

  *count = total_els;
  CFRelease(windows);
  CFRelease(app);
  return meta_els;
}

axui_meta *axui_list_from_pid_window(char *pid_str, size_t *count) {
  int pid_int = atoi(pid_str);
  if (pid_int <= 0) {
    printf("Invalid PID %d when converting %s\n", pid_int, pid_str);
    return NULL;
  }
  size_t pid = pid_int;
  return axui_list_from_process(pid, count);
}
