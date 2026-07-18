# Changelog

Notable changes to the Wirecopy client repository. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/). No release has been
tagged or published yet; everything below describes unreleased development
state.

## [Unreleased]

### Added

- Native macOS 14+ menu-bar app (Swift 6, SwiftUI): publish the clipboard with
  the Control-Option-C global shortcut, pick or drag files onto the panel,
  watch real upload progress in the menu-bar icon, and manage recent links
  (copy, open, revoke) from local history. Settings stores the server URL and
  a Keychain-held device token.
- Standalone `wirecopy` CLI with `configure`, `publish` (paths or
  `--clipboard`), `site`, `links` and `links revoke`; raw, Markdown, HTML and
  JSON output; `WIRECOPY_SERVER`, `WIRECOPY_TOKEN` and `WIRECOPY_EXPIRES_IN`
  environment overrides; documented exit codes.
- Shared `WirecopyCore` package: clipboard and file preparation, deterministic
  uncompressed ZIP archives (decision 0012), a managed API client with direct
  object uploads and lifecycle polling, output formatting and local history.
- Versioned managed API contract at `contracts/managed-api-v1.yaml`.
- Static-site publishing through the CLI `site` command for one HTML file, a
  ZIP, or a folder with a root `index.html`. The service side is implemented
  as a tracer and is currently disabled in production via
  `SITE_PUBLISHING_ENABLED: false` until a dedicated artifact domain exists
  (decision 0009).
- Governed bring-your-own-storage for site publishing: the CLI `site` command
  takes `--storage managed|byos`. `byos` publishes into your own connected
  bucket (a Pro plan with a verified storage connection set up in the web
  dashboard) while Wirecopy keeps serving, verifying, and revoking through the
  `wirecopy.site` artifact domain; `managed` is the default and omitting the
  flag stays compatible with servers that predate BYOS. Published-site
  responses now carry a `storage` field, and the managed API contract documents
  the `storage` parameter, the `plan_required` (403) and `byos_unavailable`
  (422) errors, and governed serving on the artifact domain.
- Non-interactive integration smoke (`macos/scripts/integration-smoke`) that
  boots the local Rails service, publishes through the real CLI, uploads to
  MinIO, compares exact bytes and verifies revocation.
- Visual verification harness (`WIRECOPY_UI_PREVIEW`), development install
  scripts, a local Homebrew Cask template and a CI workflow covering unit
  tests, a universal app bundle and contract/Cask syntax checks.
- Product research documentation and decision records under `docs/`.
