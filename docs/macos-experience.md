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

First-run setup asks for a shortcut and suggests a conservative default. The
recorder must validate before continuing:

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
| Multiple Finder files | Upload as a collection page or ZIP, based on the selected policy. |
| Folder | Create a ZIP while preserving the folder hierarchy. |
| PDF, audio, video, archive, document | Upload as a file; do not promise an inline preview. |
| iCloud placeholder | Request download with progress or fail with an actionable message. |
| Alias or symbolic link | Resolve according to a documented policy; never silently upload an unexpected target. |
| Application bundle/package | Ask before packaging and uploading. |
| File promise | Resolve into a controlled temporary directory with limits. |
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

The intended initial distribution is a signed and notarized application outside
the Mac App Store, with a Homebrew Cask. A separate formula may distribute a
headless CLI if it can operate independently. The App Store can be evaluated
after sandbox and extension constraints are tested.

Release documentation must include installation, update, uninstall, permission
reset and diagnostic-log instructions.
