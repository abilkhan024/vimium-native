#!/bin/zsh

set -euo pipefail

app_name="Vimium Native"
bundle_id="com.vimiumnative.app"
build_dir=".build/release"
app_path="${VIMIUM_APP_PATH:-/Applications/$app_name.app}"

swift build -c release
rm -rf "$app_path"
mkdir -p "$app_path/Contents/MacOS" "$app_path/Contents/Resources"
cp "$build_dir/VimiumNative" "$app_path/Contents/MacOS/VimiumNative"

cat >"$app_path/Contents/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleDisplayName</key>
  <string>$app_name</string>
  <key>CFBundleExecutable</key>
  <string>VimiumNative</string>
  <key>CFBundleIdentifier</key>
  <string>$bundle_id</string>
  <key>CFBundleName</key>
  <string>Vimium Native</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleShortVersionString</key>
  <string>1.10-local</string>
  <key>CFBundleVersion</key>
  <string>1</string>
  <key>LSUIElement</key>
  <true/>
  <key>NSHighResolutionCapable</key>
  <true/>
</dict>
</plist>
EOF

codesign --force --deep --sign - "$app_path"
codesign --verify --deep --strict --verbose=2 "$app_path"
scripts/launch-app.sh
