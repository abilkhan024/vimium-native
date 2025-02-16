# v0.1 checklist

1. Customization via .config file
2. Better scroll experience
3. Fuzzy find based on text attr

---

# Navigation

- Features
  - Grid meaning hints are in grid view
  - FzFind meaning FuzzyFind

# Build

```sh
# Build in release mode
swift build -c release

# Run
.build/release/VimiumNative
```

# Development

```sh
# Build in debug mode
swift build

# Build in debug and watch for file changes requires
# [watchexec](https://github.com/watchexec/watchexec)
watchexec -r 'swift build && .build/debug/VimiumNative'
```
