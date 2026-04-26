---
name: ios-sim-screenshot
description: Take a screenshot of the booted iOS simulator and display it inline. Use when the user wants to see the current state of the iOS simulator, verify UI layout, or check visual output.
---

# iOS Simulator Screenshot

Takes a screenshot of the currently booted iOS simulator and reads it back for inline display.

## Steps

1. Get the booted simulator's UDID:
```bash
xcrun simctl list devices booted
```

2. Capture the screenshot to a temp file:
```bash
xcrun simctl io <UDID> screenshot /tmp/sim-screenshot.png
```

3. Read the file to display it inline:
```
Read /tmp/sim-screenshot.png
```

## Notes
- If multiple simulators are booted, pick the one most relevant to the current project (check project.yml or build settings for deployment target).
- The screenshot captures the current screen state — make sure the app is foregrounded in the simulator.
- `xcrun simctl io` also supports `--type png` or `--type tiff` if needed.
- For physical device screenshots, use the `ios-device-logs` skill instead (or `idevicescreenshot` from libimobiledevice).
