# macOS experience

## Default interaction

1. The user copies an image or one or more files.
2. The user presses a configurable global shortcut.
3. The app validates the input before starting an upload.
4. A compact progress notification shows the file name and destination.
5. The app replaces the clipboard with the configured output.
6. A completion notification offers Copy again, Open and Revoke actions.
7. The user pastes into the application that remained focused.

The default does not synthesize a paste or press Return. Optional insertion
requires Accessibility permission and must be separately enabled.

## Entry points

All entry points should call the same publishing service.

| Entry point | Intended behavior |
| --- | --- |
| Global shortcut | Publish the best supported clipboard representation using the active preset. |
| Menu bar | Show status, recent links, destination and manual actions. |
| Finder Quick Action | Publish selected files or folders without first copying them. |
| Share extension | Accept items from applications that expose the macOS Share menu. |
| Drag to menu bar | Publish dropped files with visible feedback. |
| CLI | Publish paths or standard input and emit text or JSON. |
| Shortcuts action | Expose input, preset, output format and result fields. |

Raycast, Alfred, Herdr and editor integrations should consume the CLI or a
versioned local interface rather than duplicate upload logic.

## Shortcut setup

First-run setup suggests `Control–Option–C` and asks the user to confirm or
replace it. The recorder validates before continuing that:

- the sequence is syntactically valid;
- it is not already assigned inside the app;
- known macOS-reserved shortcuts are rejected or clearly warned;
- a registration attempt succeeds;
- a detected conflict offers retry, choose another or skip for now.

macOS does not expose a perfect registry of shortcuts used by every
application. The UI must describe conflict detection as best-effort, not a
guarantee.

## Clipboard selection rules

The pasteboard can expose multiple representations for the same item. Selection
should be deterministic:

1. copied Finder file URLs;
2. directly encoded image data with a supported type;
3. supported file promises that can be resolved safely;
4. otherwise, report that no supported image or file is available.

Plain text and an image URL are not uploaded by default. The app leaves the
clipboard untouched and explains what it expected.

## Initial compatibility matrix

“Any copied file” is a product ambition. Release claims must match tested
behavior.

| Input | Initial behavior |
| --- | --- |
| Screenshot or copied bitmap | Encode without unnecessary conversion; preserve PNG/JPEG when reliable. |
| Finder file | Upload file bytes and preserve a safe display name and MIME type. |
| Multiple Finder files | Create one deterministic ZIP locally for managed and BYOS destinations. |
| Folder | Deferred until traversal, symlink and package behavior is specified. |
| PDF, audio, video, archive, document | Upload as a file; do not promise an inline preview. |
| iCloud placeholder | Request download with progress or fail with an actionable message. |
| Alias or symbolic link | Resolve according to a documented policy; never silently upload an unexpected target. |
| Application bundle/package | Ask before packaging and uploading. |
| File promise | Deferred until resolution and resource limits are specified. |
| Very large file | Validate policy and quota before preparation or transfer. |

Temporary files must be cleaned after success, failure and application restart.

## Feedback and failure behavior

The command must never fail silently.

| State | Feedback |
| --- | --- |
| Preparing | Brief “Preparing …” status if work exceeds a small delay. |
| Uploading | File name, progress and cancel action. |
| Complete | Link copied, with Open and Revoke where available. |
| No supported input | “No image or file found on the clipboard.” |
| Invalid configuration | Open the relevant setting and preserve the original clipboard. |
| Network failure | Keep the original clipboard, show retry, and retain safe temporary preparation briefly. |
| Quota or size limit | Explain the exact limit and offer BYOS or plan-management paths where appropriate. |

The menu-bar icon provides the non-disruptive status path. Preparation,
authorization and scanning use compact processing states; direct upload uses a
rotating determinate ring driven by transmitted-byte progress. Completion
smoothly replaces the ring with a checkmark for two seconds before returning to
idle. Failure remains visible until it is dismissed or superseded by a
successful publish. The global shortcut never opens the menu automatically or
moves focus away from the initiating application.

The menu does not add a separate completion card. Newly published items appear
in Recent links with Copy, Open and Revoke actions. Copy confirmation stays
attached to the action that caused it: the row's copy icon briefly becomes a
green checkmark. Relative timestamps use minute granularity and never display
seconds. Revoke is a two-step action: the first press replaces its icon with a
compact `Delete?` button, and only pressing that confirmation performs the
remote revoke and removes the local history row. An unanswered confirmation
returns to the icon after three seconds.

System notifications should be useful when the initiating application is
full-screen or remote-focused. The menu bar should also retain the latest
result so a missed notification is not fatal.

## Permissions

Request permissions only at the point of value:

- Notifications: when the user enables system feedback.
- Accessibility: only for optional auto-insert or automatic paste.
- Finder/Share extensions: enabled through their normal system surfaces.
- Files and folders: use security-scoped access where required.

The core copy-link workflow should work without Accessibility permission.

## Distribution

The primary installation surface is a Homebrew Cask that installs a signed and
notarized application outside the Mac App Store:

```bash
brew install --cask wirecopy
```

Homebrew handles discovery, installation, upgrades and removal; it does not
define the application experience. The installed application remains a normal
native Mac app with a menu bar interface, settings and management windows.
These surfaces remain outside the default `copy → shortcut → paste` path.

Early releases may use a project-owned
[Homebrew tap](https://docs.brew.sh/How-to-Create-and-Maintain-a-Tap) before the
application is eligible for the official Cask repository:

```bash
brew install --cask <owner>/<tap>/wirecopy
```

The release archive contains the application bundle and a standalone
`wirecopy` CLI built from shared Swift packages. The Cask exposes that bundled
executable. No separate formula is planned initially; revisit it only if
independent CLI installation demonstrates clear demand.

The official Cask installs the project's signed and notarized build of the
open-source client. Installing through Homebrew should not require users to
build from source or manage signing identities.

The App Store can be evaluated after sandbox and extension constraints are
tested.

Homebrew is the update authority for Cask installations. The app may notify the
user that an update exists but must not replace the Cask-managed application.

Release documentation must include installation, update, uninstall, permission
reset and diagnostic-log instructions.

## Management surfaces

The native app owns recent links, available link actions, presets,
destinations, quota summary and local history. Managed history synchronizes
through Rails; BYOS history remains local. The Rails web application owns full
account history, aggregate link analytics, billing, account deletion and abuse
reporting.

Operational analytics in the native app are not a license for behavioral
telemetry. Optional diagnostics follow the explicit opt-in and data exclusions
in [Security and abuse](security-and-abuse.md).

## Visual language

The native app follows macOS layout and control conventions without discarding
the Wirecopy identity. Warm paper surfaces, aubergine ink, lilac and mint state
fields, the W/ wordmark and selective serif hierarchy remain shared with the
marketing page. Native grouping, focus behavior, control sizes and window
density adapt that system to macOS. Peach is reserved for the primary action;
monospaced type is limited to machine-readable values.

Menu-bar publishing stays compact and left aligned for quick pointer and
keyboard use. Settings uses the same hierarchy with native fields, segmented
controls and Keychain behavior. Both surfaces must retain platform focus,
keyboard, VoiceOver, reduced-motion and light/dark-mode behavior.
