# Plans

1. Warpd mouse functionality (may be even better by more grids)
2. Scrolling at any point to 4 dirs, and using vi style number prefix for each
   dir (may be d and u, also spam for Convenience)
3. Should select all visible windows and system tray (not latest only)
4. Better search being able to fuzzy find, sort by priory select even when
   multiple options
5. Fast hints (bg work?)
6. customization via .config file
7. Reliable calling doesn't crash or stops

---

## Current priority

- Need much faster render, and reevaluation on search for both grid and hints
  - [x] Using reactivity for instead of remount of contentView
  - [ ] May be prerender initial view and keep at 0 opacity and increase
        opacity later?
  - [ ] Introduce less intensive operations
    - [ ] For mouse
      - [ ] Custom amount of hitboxes larger the faster
    - [ ] For hints
      - [ ] Remove redundant for hints (e.g. if parent has valid children no need
            for parent? (arguable))
      - [ ] Select by mode (interactive, interactive text, lazy loaded text)?
- Secondary selection allow to scroll through current selection using arrows
  - Sorting

## Later down the road

- Rewrite state management, by at least split by module in which it's used by

# Development

## Build and run

```sh
swift build && .build/debug/VimiumNative
```

## Watch for fs changes via watchexec

```sh
watchexec -r 'swift build && .build/debug/VimiumNative'
```
