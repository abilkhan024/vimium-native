# v0.1 checklist

1. Customization via .config file
   1.1. Keys for shortcuts
2. Better scroll experience
   - Smoother, and option for scroll size
3. System level menu bar hinting
   - May be poll each n seconds
4. Fuzzy find based on text attr
   - Must tab/s-tab between hints?

---

# Known limitations

- Multiple screen navigation, for now works find when in primary only, switch
  requries restart

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
