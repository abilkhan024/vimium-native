# v0.1 checklist

1. Customization via .config file
   - Keys for shortcuts
2. Better scroll experience
   - Smoother, and option for scroll size
3. Fuzzy find based on text attr
   - Must tab/s-tab between hints?

---

# Installing

## Prerequisites

Enable following env's so then procceed which ever step you want

```sh
export VIMIUM_APP=VimiumNative
export VIMIUM_APP_ID=com.vimium.$VIMIUM_APP
# NOTE: VIMIUM_INSTALL_LOCATION won't be respected when installing, so stick
# with default instead, it's used to make distribution testing convenience only
export VIMIUM_INSTALL_LOCATION=/usr/local/bin/$VIMIUM_APP
```

## Install & Run

```sh
# Download and install pkg from `Releases` section

# Run using:
$VIMIUM_INSTALL_LOCATION/VimiumNative
```

## Usage

```sh
# Run in foreground, recommended when getting started for the first time
$VIMIUM_INSTALL_LOCATION/VimiumNative

# Run in daemon (detached mode)
$VIMIUM_INSTALL_LOCATION/VimiumNative daemon

# Kill the daemon
$VIMIUM_INSTALL_LOCATION/VimiumNative kill
```

### Uninstall

If you didn't like the application you can easily uninstall it by following:

_P.S. constructive criticism is appreciated in the `Issues` section_

```sh
# Verify that env's are set correctly
echo $VIMIUM_INSTALL_LOCATION
echo $VIMIUM_APP_ID

# Remove files
sudo rm -rf $VIMIUM_INSTALL_LOCATION
# Forget the package
sudo pkgutil --forget $VIMIUM_APP_ID
# Delete package receipt
ls /var/db/receipts/ | grep $VIMIUM_APP_ID | xargs -I{} sudo rm -rf /var/db/receipts/{}
```

### `pkgbuild` for distribution

Showed for transparency of the build step, no need to run it

```sh
# Build the application
swift build -c release

# Creating installable package
pkgbuild --root .build/release --identifier $VIMIUM_APP_ID --version 1.0 --install-location $VIMIUM_INSTALL_LOCATION $VIMIUM_APP.pkg
```

# Building from source

```sh
# Prerequisite: Clone however you want and cd into the dir

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
