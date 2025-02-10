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
    - [ ] Keep render instance and bring them to the front, create some sort
          window manager for each window, grid, labeled-hints
  - [ ] Introduce less intensive operations
    - [ ] For mouse
      - [ ] Custom amount of hitboxes larger the faster
    - [ ] For hints
      - [ ] Remove redundant for hints (e.g. if parent has valid children no need
            for parent? (arguable))
      - [ ] Select by mode (interactive, interactive text, lazy loaded text)?
- Secondary selection allow to scroll through current selection using arrows
  - Sorting

```swift
// For faster chagne detection keep track of every
// element in some internal ds and show current ready state
// and revalidate if need more append new hints, 
// keeping all the previous with the same label, you could cmp
var updated = false
var count = 0
observer = app.createObserver { (observer: Observer, element: UIElement, event: AXNotification, info: [String: AnyObject]?) in
    // var elementDesc: String!
    count += 1
    print(event, count, element.description)
}

try observer.addNotification(.created, forElement: app)
try observer.addNotification(.moved, forElement: app)
try observer.addNotification(.layoutChanged, forElement: app)
try observer.addNotification(.valueChanged, forElement: app)
try observer.addNotification(.selectedChildrenMoved, forElement: app)
try observer.addNotification(.titleChanged, forElement: app)
try observer.addNotification(.uiElementDestroyed, forElement: app)

// still don't know how to address
```

## Later down the road

- Rewrite state management, by at least split by module in which it's used by
- Change to rcmd + / later with some key like s

# Navigation

- Features
  - Grid meaning hints are in grid view
  - FzFind meaning FuzzyFind

# Development

## Build and run

```sh
swift build && .build/debug/VimiumNative
```

## Watch for fs changes via watchexec

```sh
watchexec -r 'swift build && .build/debug/VimiumNative'
```
