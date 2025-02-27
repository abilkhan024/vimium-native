# Demo (TODO)

## Hint

## Hint with search

## Grid

## Scroll

# Getting started

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

# Options

Avialbable options are documented in following file
[AppOptions.swift](https://github.com/abilkhan024/vimium-native/blob/main/Sources/VimiumNative/App/AppOptions.swift)

Example config:

```sh
# Mouse params when entering grid mode

# Color by default
mouse_color_normal=#ff0000
# Color when dragging
mouse_color_visual=#00ffff
# Color of the outiline when in mouse mode
mouse_outline_color=#00ffff
# Hides Outline when set to 0
mouse_outline_width=8.0
# Virtual circle cursor size
mouse_size=10.0

# Scroll scale vertical when using jk, horizontal for hl, verticalPage: du
scroll_size_vertical=5
scroll_size_horizontal=40
scroll_size_vertical_page=100

# Cursor move size
cursor_step=5

# Traverse the children of the node if the node has dimensions of <=1
# Generally advised against, because slows down performance
traverse_hidden=false

# Interval for system menu poll in seconds, 0 doesn't poll system menu
# therefore won't show it. Min value that won't degrade performance is 10
system_menu_poll=10

# Colors used for hints
color_bg=#e6d278
color_fg=#000000

# Chars that will be used when generating hints
hint_chars=jklhgasdfweruio

# Some websites may use text as buttons. You can enable this to hint text nodes,
# but it may slow down rendering, sometimes significantly.
# P.s HomeRow doesn't do it, that's why it's false by default
hint_text=false

# How to determine if the element is hintable.
# Possible values: action | role
# ----------------------------------------------------------------
# role: Replicates HomeRow behavior, generally faster but ignores some elements
# action: Shows if element provides non-ignored action
# ----------------------------------------------------------------
hint_selection=role

# Rows and cols dimensions when using grid mode.
# Change is a trade-off between precision and performance
grid_rows=36
grid_cols=36
grid_font_size=14.0

# Sometimes macOS refuses to register drag when you immediately jump
# between labels. You can enable this flag to jiggle once you start dragging
jiggle_when_dragging=false

# When developing and want to check performance
debug_perf=false
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
- Smooth scrolling _(feel free to contribute if that's an issue)_
