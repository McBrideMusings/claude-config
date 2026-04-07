---
name: ios-device-logs
description: Use when debugging an iOS app on a physical device and you need to see logs, diagnose connection issues, or investigate crashes. Triggers on symptoms like silent failures, flickering, missing errors, or when the user says the app is misbehaving on their phone.
---

# iOS Device Logs

Stream or collect logs from a connected physical iOS device, filtered to a specific app.

## Tools

**`idevicesyslog`** (libimobiledevice) — live streaming from device. Works without sudo.

**`log collect`** + **`log show`** — collect a logarchive from the device for historical analysis. Requires sudo.

## Live Stream (Primary Method)

```bash
# Stream all logs from a specific process
idevicesyslog -p ProcessName

# Stream logs matching a substring (subsystem, category, message text)
idevicesyslog -m "com.example.myapp"

# Combine: process filter + keyword match
idevicesyslog -p MyApp -m "Connection"

# Quiet mode: exclude common noisy system processes
idevicesyslog -p MyApp -q

# Write to file while streaming
idevicesyslog -p MyApp -o /tmp/app-logs.txt

# Start capturing only when a specific event occurs
idevicesyslog -p MyApp -t "error" -T "recovered"
```

**Key flags:**
- `-p PROCESS` — filter by process name (as shown in device process list)
- `-m STRING` — only show lines containing STRING
- `-M STRING` — exclude lines containing STRING
- `-t STRING` / `-T STRING` — trigger start/stop on match
- `-q` — exclude common noisy processes
- `-o FILE` — write to file instead of stdout

**Find process names:** `idevicesyslog pidlist`

## Collect Archive (Historical Logs)

```bash
# Collect last N seconds of logs from device (no sudo needed)
idevicesyslog archive /tmp/device.tar --age-limit 600

# Extract and query
mkdir -p /tmp/device-logs && tar xf /tmp/device.tar -C /tmp/device-logs
mv /tmp/device-logs /tmp/device-logs.logarchive
log show /tmp/device-logs.logarchive --predicate 'subsystem CONTAINS "myapp"' --style compact
```

## Important: Log Level Gotcha

iOS only **persists** `default` level and above in logarchives. `Logger.info()` and `Logger.debug()` messages are **not persisted** — they only appear in live streams.

If you're not seeing expected log messages in an archive:
- Switch to live streaming with `idevicesyslog`
- Or change the app's log calls from `.info()` to `.notice()` or `.error()` for messages you need persisted

| Swift Log Level | Persisted in Archive? | Shows in Live Stream? |
|---|---|---|
| `.fault` | Yes | Yes |
| `.error` | Yes | Yes |
| `.default` / `.notice` | Yes | Yes |
| `.info` | No | Yes |
| `.debug` | No | Only with config |

## Predicate Syntax (for `log show`)

```bash
# By subsystem
--predicate 'subsystem == "com.example.myapp"'

# By subsystem prefix (catches sub-subsystems)
--predicate 'subsystem CONTAINS "example"'

# By category within subsystem
--predicate 'subsystem == "com.example.myapp" AND category == "Network"'

# By message content
--predicate 'eventMessage CONTAINS "error"'
```

## Common Mistakes

- **Using `log show --device`**: This flag doesn't exist. Use `idevicesyslog` or `log collect` instead.
- **Missing logs in archive**: Check log level — `.info()` isn't persisted. Use live stream or raise log level.
- **Process name mismatch**: The process name may differ from the app name. Use `idevicesyslog pidlist` to find it.
- **Shell quoting**: Predicates with quotes need careful escaping. Use single quotes around the predicate string.
