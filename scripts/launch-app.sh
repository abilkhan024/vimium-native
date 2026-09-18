#!/bin/zsh

set -euo pipefail

app_path="${VIMIUM_APP_PATH:-/Applications/Vimium Native.app}"
binary_path="$app_path/Contents/MacOS/VimiumNative"
log_path="${TMPDIR:-/tmp}/vimium-native.log"

pkill -f "$binary_path" 2>/dev/null || true
rm -f "$log_path"
nohup "$binary_path" >"$log_path" 2>&1 &
printf 'Started Vimium Native (PID %s). Log: %s\n' "$!" "$log_path"
