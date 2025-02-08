# Plans

- Reliable calling doesn't crash or stops
- Fast hints (bg work?)
- Warpd mouse functionality (may be even better by more grids)
- Should select all visible windows and system tray (not latest only)
- Better search being able to fuzzy find
- Scrolling at any point to 4 dirs, and using vi style number prefix for each
  dir (may be d and u, also spam for Convenience)
- customization via .config file

# Development

## Build and run

```sh
swift build && .build/debug/VimiumNative
```

## Watch for fs changes via watchexec

```sh
watchexec -r 'swift build && .build/debug/VimiumNative'
```
