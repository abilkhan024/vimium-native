# v0.1 checklist

1. Customization via .config file
   - Keys for shortcuts
2. Better scroll experience
   - Smoother, and option for scroll size

---

# Usage

## Install

Install pkg from
[Releases](https://github.com/abilkhan024/vimium-native/releases) section.

## Run

After installing pkg binary will be available that you can run you can add alias
in your rc file

```sh
/usr/local/bin/VimiumNative/VimiumNative
```

## Uninstall

If you didn't like the application you can easily uninstall it by following:

_P.S. constructive criticism is appreciated in the `Issues` section_

```sh
# Verify that env's are set correctly
# Remove files
sudo rm -rf /usr/local/bin/VimiumNative
# Forget the package
sudo pkgutil --forget com.vimium.VimiumNative
# Delete package receipt if anything is left
ls /var/db/receipts/ | grep com.vimium.VimiumNative | xargs -I{} sudo rm -rf /var/db/receipts/{}
```

### `pkgbuild` for distribution

Showed for transparency of the build step, no need to run it

```sh
# Build the application
swift build -c release

# Creating installable package
pkgbuild --root .build/release --identifier com.vimium.VimiumNative --version 1.0 --install-location /usr/local/bin/VimiumNative VimiumNative.pkg
```

# Building from source

```sh
# Prerequisites: 
# - Clone however you want and cd into the dir
# - Ensure that dev utils are installed so swift is avialable and matches
#   with Package.swift version (6.0 as of now)

# Build in release mode
swift build -c release

# Run
.build/release/VimiumNative
```

# Development

It's almost the same as you would build from source :)

```sh
# Build in debug mode
swift build

# Build in debug and watch for file changes requires
# [watchexec](https://github.com/watchexec/watchexec)
watchexec -r 'swift build && .build/debug/VimiumNative'
```

# Known limitations

- Multiple screen navigation, fzfind works for main screen only _(feel free to
  contribute if that's an issue)_
- Chrome may fail to index the window elements, ensure that flag
  `Native accessibility API support` in [accessibility](chrome://accessibility)
  is enabled
