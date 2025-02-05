#include <stdarg.h>
#include <stdio.h>

void log_vb(const char *format, ...) {
#ifdef VERBOSE_LOG
  va_list args;
  va_start(args, format);

  for (const char *p = format; *p; ++p) {
    if (*p == '%' && *(p + 1)) {
      ++p;
      switch (*p) {
      case 'd': { // Integer
        int i = va_arg(args, int);
        printf("%d", i);
        break;
      }
      case 'c': { // Character
        int c = va_arg(args, int);
        putchar(c);
        break;
      }
      case 's': { // String
        char *s = va_arg(args, char *);
        printf("%s", s);
        break;
      }
      case 'f': { // Floating point
        double f = va_arg(args, double);
        printf("%f", f);
        break;
      }
      case 'z': { // Size type (size_t)
        if (*(p + 1) == 'u') {
          ++p;
          size_t z = va_arg(args, size_t);
          printf("%zu", z);
        }
        break;
      }
      case 'l': {                                 // Long integer
        if (*(p + 1) == 'l' && *(p + 2) == 'u') { // %llu
          p += 2;
          unsigned long long llu = va_arg(args, unsigned long long);
          printf("%llu", llu);
        } else if (*(p + 1) == 'd') { // %ld
          ++p;
          long ld = va_arg(args, long);
          printf("%ld", ld);
        }
        break;
      }
      default:
        putchar('%');
        putchar(*p);
      }
    } else {
      putchar(*p);
    }
  }

  va_end(args);
  printf("\n");
#endif
}
