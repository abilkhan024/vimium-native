# v0.1 checklist

1. Customization via .config file
   1.1. Keys for shortcuts
2. Better scroll experience
   - Smoother, and option for scroll size
3. Fuzzy find based on text attr
   - Must tab/s-tab between hints?

---

# Build

```sh
# Build in release mode
swift build -c release

# Run
.build/release/VimiumNative
```

# Distribution

## Prerequisites

```sh
export VIMIUM_APP=VimiumNative
export VIMIUM_APP_ID=com.vimium.$VIMIUM_APP
# NOTE: Assumes $HOME var is available, also it doesn't respect the value
# if you change it stick with default please, used for convenience only
export VIMIUM_INSTALL_LOCATION=$HOME/bin/$VIMIUM_APP
```

## Run

```sh
$VIMIUM_INSTALL_LOCATION/VimiumNative
```

## Build for distribution

Showed for transparency of the build step, no need to run it

```sh
# Creating installable package
pkgbuild --root .build/release --identifier $VIMIUM_APP_ID --version 1.0 --install-location $VIMIUM_INSTALL_LOCATION $VIMIUM_APP.pkg
```

## Uninstall distributed version

```sh
# Verify that vars set correctly
echo $VIMIUM_INSTALL_LOCATION
echo $VIMIUM_APP_ID

# Remove files
sudo rm -rf $VIMIUM_INSTALL_LOCATION
# Forget the package
sudo pkgutil --forget $VIMIUM_APP_ID
# Delete package receipt
ls /var/db/receipts/ | grep $VIMIUM_APP_ID | xargs -I{} sudo rm -rf /var/db/receipts/{}
```

# Development

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
