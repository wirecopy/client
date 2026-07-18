# 0013: Register the global shortcut with Carbon RegisterEventHotKey

- Status: Accepted and implemented
- Date: 2026-07-18 (recorded retroactively; the implementation already shipped
  with the native client in `WirecopyMac/GlobalShortcut.swift`)

## Context

The core interaction is copy, press one system-wide shortcut, paste a link.
The menu-bar app has no key window when the shortcut fires, so it needs a
mechanism that captures a keyboard chord globally.

The modern options each have a cost. An `NSEvent` global keyboard monitor
requires the user to grant an Accessibility/Input Monitoring permission before
any key event is delivered, and it observes rather than consumes the chord, so
the keystroke still reaches the frontmost app. A `CGEventTap` has the same
permission requirement. Third-party shortcut packages (MASShortcut-style
libraries) ultimately wrap the same Carbon hotkey API while adding an external
dependency to a package that currently has none.

The legacy Carbon `RegisterEventHotKey` API needs no permission prompt,
consumes the chord and delivers it to the application event target even when
the app is in the background. Carbon is deprecated, but this specific API has
remained functional across macOS releases and is what the shortcut ecosystem
is built on.

## Decision

`GlobalShortcut` in `WirecopyMac` installs a Carbon event handler for
`kEventHotKeyPressed` and registers one hardcoded hotkey: `kVK_ANSI_C` with
`controlKey | optionKey`, that is Control-Option-C. The handler posts an
internal `.wirecopyShortcut` notification on the main queue; publishing logic
lives elsewhere. Registration status is logged via `NSLog` and both the hotkey
and the handler are unregistered on deinit. No third-party dependency is
introduced.

## Consequences

- The shortcut works immediately with no Accessibility or Input Monitoring
  prompt, keeping first-run friction at zero.
- The chord is not user-configurable yet; changing it requires a code change.
  A conflict with another app's Control-Option-C binding cannot be resolved by
  the user.
- Registration failure (for example, another app already owns the chord) is
  only logged, not surfaced in the UI.
- The API is deprecated but stable; if Apple ever removes it, the replacement
  will likely require a permission-gated mechanism or a new system API.
- `kVK_ANSI_C` is a physical key position, so on non-ANSI layouts the chord
  follows the key location rather than the letter printed on it.

## Alternatives considered

- `NSEvent.addGlobalMonitorForEvents` / `CGEventTap`: rejected because they
  require an upfront permission grant for a menu-bar utility's primary action,
  and the monitor variant cannot consume the chord.
- MASShortcut-style dependencies: rejected because they wrap the same Carbon
  API and would add third-party surface for functionality that is currently a
  page of code. They become worth revisiting when user-configurable recording
  UI is needed.

## Revisit when

- user-configurable shortcuts are prioritized, which needs recording UI,
  persistence and conflict handling;
- registration failures need to be surfaced in Settings instead of logs;
- a macOS release breaks or removes `RegisterEventHotKey`.
