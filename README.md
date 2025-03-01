# Overview

`VimiumNative` is a free and open-source cli tool that allows you to use your
mac without mouse in your day to day. It's some combination of other tools like
`HomeRow`, `Shortcat`, `Mouseless`, `Warpd`. To some degree you may use this app
as an alternative to any of them. If you find that some part lacks in
functionality or performance it's higly encouraged to contribute to the project
:)

P.S. More about contribution to the project could be found [here](#contriubtion)

# Quick demo

https://abilkhan024.github.io/vimium-native-demo.mp4

## Breakdown

Let's breakdown what is being showed on the demo, to start using the app

### Hints

Trigger hint view by pressing `Cmd + Shift + .` which will hint interactive
elements, which you can click, if some hints overlap you can toggle their
z-index by pressing `;`

### Hints with search

Trigger hint view by pressing default key binding of `Cmd + Shift + .` which
will hint interactive elements, press `/` which will enter search mode and start
typing the text that you want to click, once the hint is focused press enter

### Grid & Mouse

Trigger grid view by pressing default key binding of `Cmd + Shift + ,` which
will show labeled cells where you can place your mouse, and left click using
`<CR>` (aka Enter), or right click using `.`, or move your mouse using `hjkl`
(directions are just like in vi), toggle dragging by pressing `v`, show grid
hint again to place mouse to different point using `/`

### Scroll

Trigger scrolling by pressing default key binding of `Cmd + Shift + j`, now you
can use keys `d,u,<S>h,<S>j,<S>k,<S>l` directions are just like in vi (`<S>`
indicates shift) to scroll the current cursor position which is center of screen
by default

## Keybindings

Every keybinding used in this demo can be customized using config file more in
[options](#options)

# Getting started

## Install

Install pkg from
[Releases](https://github.com/abilkhan024/vimium-native/releases) section.

It will show that the package is malware when you try to open it because it's
not notarized as notarization requires apple's paid developer account

To install anyways go to
`Settings -> Privacy & Security -> Open VimiumNative anyway`

## Run

After installing pkg binary will be available that you can run you can add alias
in your rc file

```sh
alias vinative="/usr/local/bin/VimiumNative/VimiumNative"

# Runs the binary
vinative
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
# Build the application striping symbols
swift build --disable-prefetching -Xswiftc -gnone -c release --scratch-path /tmp/vimium-native-build

# Remove unnecessary files that expose symbols
rm -rf /tmp/vimium-native-build/arm64-apple-macosx/release/swift-version*.txt && \
rm -rf /tmp/vimium-native-build/arm64-apple-macosx/release/description.json && \
rm -rf /tmp/vimium-native-build/arm64-apple-macosx/release/ModuleCache && \
rm -rf /tmp/vimium-native-build/arm64-apple-macosx/release/Modules && \
rm -rf /tmp/vimium-native-build/arm64-apple-macosx/release/VimiumNative.build && \
rm -rf /tmp/vimium-native-build/release.yaml && \
rm -rf /tmp/vimium-native-build/build.db

# Creating installable package
pkgbuild --root /tmp/vimium-native-build/release --identifier com.vimium.VimiumNative --version 1.0 --install-location /usr/local/bin/VimiumNative VimiumNative.pkg
```

# Options

Config file will be read from $HOME/.config/vimium or `$VIMIUM_CONFIG_PATH` if
it's set

Default config:

```sh
# Key bindings, format is <Mod>{key} mapping can be found in 
# `Sources/VimiumNative/Core/KeyMapping.swift` -> `let mappingToValue`
key_show_hints='<D><S>.'
key_show_grid='<D><S>,'
key_start_scroll='<D><S>j'
key_close='<Esc>'
key_enter_search_mode='/'
key_next_search_occurence='<Tab>'
key_prev_search_occurence='<S><Tab>'
key_select_occurence='<CR>'
key_drop_last_search_char='<BS>'
key_toggle_z_index=';'
key_mouse_left='h'
key_mouse_down='j'
key_mouse_up='k'
key_mouse_right='l'
key_scroll_left='<S>h'
key_scroll_down='<S>j'
key_scroll_up='<S>k'
key_scroll_right='<S>l'
key_scroll_page_down='d'
key_scroll_page_up='u'
key_scroll_full_down='<S>g'
key_scroll_full_up='g'
key_enter_visual='v'
key_reopen_grid_view='/'
key_right_click='.'
key_left_click='<CR>'

# Font size of the hint label
hint_font_size=14.0

# Height of the triangle indicating point that will be clicked
hint_triangle_height=6.0

# Mouse params when entering grid mode:
# Color by default
mouse_color_normal=#ff0000
# Color when dragging
mouse_color_visual=#00ffff
# Color of the outline when in mouse mode
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
# - Ensure that dev utils are installed so swift is available and matches
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

# Known limitations

- Multiple screen navigation, fzfind works for main screen only _(feel free to
  contribute if that's an issue)_
- Smooth scrolling _(feel free to contribute if that's an issue)_
