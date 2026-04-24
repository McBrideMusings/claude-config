---
name: smb-automount-macos
description: How SMB shares auto-mount silently on this Mac. Use when the user asks about SMB/CIFS/network share mounting, the piercetower shares, Finder password prompts that won't go away, or mount-related LaunchAgents. Also use when troubleshooting "why did a password popup appear" or "why did my shares disappear."
---

# SMB Auto-Mount on macOS

## The setup

Two files drive this:

- **`~/Library/LaunchAgents/com.pierce.mount-piercetower.plist`** — LaunchAgent, runs every 60s (`StartInterval`), also fires at login (`RunAtLoad`). Invokes the script below.
- **`~/Library/Scripts/mount-piercetower.sh`** — the actual mount logic.

Load/unload:
```bash
launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/com.pierce.mount-piercetower.plist
launchctl bootout   gui/$(id -u)/com.pierce.mount-piercetower
```

## Script logic (and why it's this way)

```bash
#!/bin/bash
host=piercetower.lan
user=pierce
shares=(programs storage media)

/usr/bin/nc -z -G 1 "$host" 445 >/dev/null 2>&1 || exit 0

for share in "${shares[@]}"; do
    mountpoint="/Volumes/$share"
    if mount | grep -q " on $mountpoint "; then
        continue
    fi
    mkdir -p "$mountpoint" 2>/dev/null
    /sbin/mount_smbfs "//$user@$host/$share" "$mountpoint" >/dev/null 2>&1 || rmdir "$mountpoint" 2>/dev/null
done
```

### Design rules (do not violate)

1. **Probe before mount.** `nc -z -G 1 <host> 445` with a 1s connect timeout. If the host isn't reachable, exit 0 *silently*. No retry loop, no error, no log line. Failing to mount an unreachable host is the expected state, not an error.
2. **Use `mount_smbfs`, never `open smb://`.** `open` hands off to Finder/LaunchServices, which has a flaky auth path that frequently ignores Keychain and triggers a GUI password dialog — even when the password is stored. `mount_smbfs` is a pure CLI utility: no GUI, no popup on any failure mode (auth, unreachable, stale mount, etc.). All errors are stderr-only.
3. **Silence stderr.** Auth failures, stale mountpoints, anything — the user does not want to be notified. They notice when a share isn't mounted and fix it manually. Surprise popups on a 60s timer are worse than silent failure.
4. **Clean up empty mountpoints on failure.** `rmdir` only succeeds on empty directories, so it's safe — it removes stub dirs we created but couldn't mount onto, and is a no-op if the mount succeeded (mountpoint isn't empty) or if the dir wasn't ours.
5. **No notifications on success either.** The share appearing in Finder is the feedback. Anything else is noise.

## Credentials

`mount_smbfs //user@host/share` looks up the Keychain entry with:
- `srvr=<host>`, `acct=<user>`, `ptcl="smb "` (four chars, trailing space)
- class = Internet Password ("inet")

These get created automatically the first time the user mounts via Finder with "Remember this password in my keychain" ticked. You should **not** need to create one manually — if one is missing, have the user mount once through Finder with the checkbox, and `mount_smbfs` will pick it up from then on.

Inspect with:
```bash
security find-internet-password -s <host>
```

## Adding a new host or share

Edit the script's `host`, `user`, and `shares` array. If it's a different host, write a new script + LaunchAgent pair rather than multiplexing — keeps failure modes independent.

## What NOT to do

- Don't add retry/backoff logic. The 60s timer *is* the retry.
- Don't add logging of failures. The user explicitly doesn't want this.
- Don't use `osascript` / AppleScript to mount — same Finder path as `open smb://`, same popup problems.
- Don't use `automount`/autofs unless you want to rearchitect. The LaunchAgent + script approach is deliberately simple and debuggable.
- Don't send notifications on success or failure. Silent is the contract.

## Debugging

If shares aren't mounting:

1. Can you reach the host? `nc -z -G 1 piercetower.lan 445; echo $?` — 0 means reachable.
2. Is Keychain entry present? `security find-internet-password -s piercetower.lan`
3. Does manual mount work? `/sbin/mount_smbfs //pierce@piercetower.lan/media /Volumes/media` — run this *without* stderr redirect to see the actual error.
4. Is the LaunchAgent loaded? `launchctl list | grep mount-piercetower`
5. Is the timer firing? `log show --predicate 'process == "launchd"' --last 5m | grep mount-piercetower`
