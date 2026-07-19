# 0015: Distribute the canonical CLI through npm

- Status: Accepted and implemented
- Date: 2026-07-20
- Supersedes: [0007](0007-homebrew-cask-and-cli.md)

## Context

The first implementation bundled a native Swift CLI with the macOS application
in one Homebrew Cask. Static-site publishing has since become a primary
developer and agent workflow. Requiring the Mac application excludes Linux,
Windows, containers and most CI environments, while shipping the same
`wirecopy` command through both Homebrew and npm creates conflicting ownership
of one executable.

The managed API already exposes the required device-token contract for direct
file uploads, site publishing, link listing and revocation. Node.js provides a
portable runtime already present in the target agent and frontend workflows.

## Decision

Publish the canonical cross-platform CLI as the unscoped public npm package
`wirecopy`. Keep the native macOS application in a Homebrew Cask, but do not
expose a second `wirecopy` executable from that Cask.

- `npx wirecopy site ./dist` is the zero-install path.
- `npm install --global wirecopy` installs the persistent command.
- The package supports maintained Node.js releases from Node 20.11 onward.
- The npm CLI lives in `cli/` in the public client repository and consumes the
  same pinned OpenAPI contract as the native client.
- The package has no runtime dependencies. It uses native `fetch`, streams file
  bytes directly to scoped object-storage grants and writes deterministic ZIP
  archives locally.
- Device tokens come from the authenticated web dashboard. Local configuration
  is permission-restricted; CI uses `WIRECOPY_TOKEN`.
- Human progress goes to stderr. URLs and versioned JSON results go to stdout.
- Releases use npm Trusted Publishing from GitHub Actions with provenance after
  the initial package reservation.
- Keep the Swift CLI source temporarily as a parity oracle and local integration
  client. Do not distribute it in the Cask; remove it after npm parity has been
  proven against production.

## Consequences

### Positive

- One installation path serves macOS, Linux, Windows, containers and CI.
- Coding agents can publish with `npx` without installing the Mac application.
- Homebrew and npm no longer compete to own the `wirecopy` executable.
- The small dependency-free package is easy to inspect and inexpensive to
  download on ephemeral runners.
- Native UI and CLI releases can evolve at appropriate cadences.

### Negative

- CLI users need a supported Node.js runtime.
- The TypeScript CLI duplicates a small amount of orchestration already present
  in Swift.
- Local tokens cannot rely on the Mac application's Keychain access group.
- Contract parity must be tested across two client implementations until the
  Swift CLI is retired.

## Alternatives considered

### Keep the CLI inside the Homebrew Cask

This preserves one native artifact but excludes non-Mac automation and makes
`npx` impossible.

### Publish native executables for every platform

This avoids a Node.js requirement but introduces cross-compilation, signing and
release-matrix work before the CLI behavior has stabilized.

### Publish both the Cask binary and npm command

This provides two installation paths on macOS but creates ambiguous upgrades
and path precedence for the same executable name.

## Revisit when

- Node.js availability becomes a material adoption constraint;
- a standalone native binary provides measured startup or packaging benefits;
- browser-based device authorization replaces manual token provisioning.
