# 4 Me

```sh
swift build -c release && \ # Build in release mode
cp .build/release/VimiumNative VimiumNative.app/Contents/MacOS && \ # Move executable to Macos.app
echo 'START:' > ~/VimiumNative.log && \ # Reset debug log
open VimiumNative.app && \ # Open applicatino
clear && \ # Clear build output
tail -f ~/VimiumNative.log # Watch debug notes
```
