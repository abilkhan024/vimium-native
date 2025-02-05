#include <AppKit/AppKit.h>
#import <Cocoa/Cocoa.h>
#include <Foundation/Foundation.h>
#include <stdio.h>

@interface AppDelegate : NSObject <NSApplicationDelegate>
@end

@implementation AppDelegate

NSColor *nscolor_from_hex(const char *str) {
  ssize_t len;
  uint8_t r, g, b, a;
#define X2B(c) ((c >= '0' && c <= '9') ? (c & 0xF) : (((c | 0x20) - 'a') + 10))

  if (str == NULL)
    return 0;

  str = (*str == '#') ? str + 1 : str;
  len = strlen(str);

  if (len != 6 && len != 8) {
    fprintf(stderr, "Failed to parse %s, paint it black!\n", str);
    return NSColor.blackColor;
  }

  r = X2B(str[0]);
  r <<= 4;
  r |= X2B(str[1]);

  g = X2B(str[2]);
  g <<= 4;
  g |= X2B(str[3]);

  b = X2B(str[4]);
  b <<= 4;
  b |= X2B(str[5]);

  a = 255;
  if (len == 8) {
    a = X2B(str[6]);
    a <<= 4;
    a |= X2B(str[7]);
  }

  return [NSColor colorWithCalibratedRed:(float)r / 255
                                   green:(float)g / 255
                                    blue:(float)b / 255
                                   alpha:(float)a / 255];
}

static NSDictionary *get_font_attrs(const char *family, NSColor *color, int h) {
  NSDictionary *attrs;

  int ptsz = h;
  CGSize size;
  do {
    NSFont *font = [NSFont fontWithName:[NSString stringWithUTF8String:family]
                                   size:ptsz];
    if (!font) {
      fprintf(stderr, "ERROR: %s is not a valid font\n", family);
      exit(-1);
    }
    attrs = @{
      NSFontAttributeName : font,
      NSForegroundColorAttributeName : color,
    };
    size = [@"m" sizeWithAttributes:attrs];
    ptsz--;
  } while (size.height > h);

  return attrs;
}

void render_rect() {
  NSRect rect = NSMakeRect(0, 0, (float)100, (float)100);

  NSWindow *nsWin =
      [[NSWindow alloc] initWithContentRect:rect
                                  styleMask:NSWindowStyleMaskBorderless
                                    backing:NSBackingStoreBuffered
                                      defer:FALSE];

  [nsWin setBackgroundColor:nscolor_from_hex("#ff0000")];
  [nsWin setLevel:NSMainMenuWindowLevel];
  [nsWin makeKeyAndOrderFront:nil];
}

- (void)applicationDidFinishLaunching:(NSNotification *)notification {
  NSLog(@"Creating");
  render_rect();
  NSLog(@"End");
}
@end

void *render_start() {
  @autoreleasepool {
    NSApplication *app = [NSApplication sharedApplication];
    AppDelegate *appdel = [[AppDelegate alloc] init];
    app.delegate = appdel;
    [app run];
    return NULL;
  }
}
