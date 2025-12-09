# Contriubtion

There is no particular strong code style or principles in this project, so do
whatever you see fit, minor adjustments can be done at any moment later.

However fews key things that needs to be followed:

- Ensure that app is always runnable simply by running `swift build` without
  relying on IDE/Xcode features
- Don't add any dependencies because most of the times they are not required,
  rely only on stdlib

Preferred: format your code using
[swift-format](https://github.com/swiftlang/swift-format)

# Development Builds

It's almost the same as you would build from source :)

```sh
# Build in debug mode
swift build

# Build in debug and watch for file changes requires
# [watchexec](https://github.com/watchexec/watchexec)
watchexec -r 'swift build && .build/debug/VimiumNative'
```
