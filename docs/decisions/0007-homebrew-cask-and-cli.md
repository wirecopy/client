# 0007: Distribute the app and CLI in one Homebrew Cask

- Status: Accepted for implementation
- Date: 2026-07-16

## Context

Homebrew is the selected installation surface, but users still need a native UI
for settings, history, account usage and link management. The CLI is also a
first-class developer surface and should not require the GUI to be running.

Separate Cask and formula releases would duplicate versioning, signing and
upgrade coordination before independent CLI installation has proven demand.

## Decision

Ship one signed and notarized universal `Wirecopy.app` through a Homebrew Cask.
Bundle the standalone `wirecopy` executable in the release archive and expose it
through the Cask's binary artifact.

- The CLI and app share Swift packages but run as independent processes.
- Start in a project-owned tap; pursue the official Cask repository when
  eligible.
- Do not publish a separate formula initially.
- Homebrew owns updates for a Cask installation. The app may notify users of an
  update but does not self-replace.
- The installed app may show full native management UI; Homebrew constrains
  packaging, not product interface.

## Consequences

### Positive

- One version identifies the compatible app, CLI and managed API contract.
- Users receive a signed native UI and pipeable CLI from one command.
- Release, notarization and rollback paths stay unified.

### Negative

- CLI-only users download the application bundle.
- Self-built CLIs cannot assume access to the official Keychain group and need a
  dashboard-issued device/personal token path.
- Cask packaging must preserve the embedded binary path across updates.

## Revisit when

- meaningful CLI-only demand justifies a formula;
- App Store distribution becomes viable;
- independent app and CLI release cadences become necessary;
- Homebrew policy requires a different artifact layout.
