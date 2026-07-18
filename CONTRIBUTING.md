# Contributing

Wirecopy's client is a Swift package with no third-party dependencies. This
repository holds the open-source Mac app, CLI, shared publishing model and the
managed API contract. The Rails managed service lives in a separate, private
repository; contributions here cannot change service behavior, only the client
and the published contract.

## Toolchain

- Swift 6 (`swift-tools-version: 6.0` in `macos/Package.swift`)
- macOS 14 or newer

Build and test from the package directory:

```sh
cd macos
swift build
swift test
swift run WirecopyApp
```

See [macos/README.md](macos/README.md) for configuring the app against a local
service, the visual verification harness and the CLI.

## Integration smoke

```sh
cd macos
./scripts/integration-smoke
```

This requires the private service repository checked out as a sibling at
`../../service` relative to `macos/`, with its Docker (PostgreSQL, MinIO) and
mise toolchain available. The script boots Rails on an isolated port (override
with `WIRECOPY_SMOKE_PORT`), provisions a temporary device token, publishes
through the real CLI, compares downloaded bytes, verifies revocation and
cleans up. Contributors without service access can rely on `swift test` and
CI; the maintainers run the smoke before merging changes that touch the
publish path.

## Documentation

Markdown is linted with markdownlint-cli2 using the repository's
`.markdownlint-cli2.jsonc` (80-column lines outside code blocks and tables):

```sh
npx markdownlint-cli2 "**/*.md"
```

Significant choices — anything that should not be reopened accidentally — get
a decision record in [docs/decisions/](docs/decisions/) using the next
four-digit number and the existing structure: status, date, context, decision,
consequences and alternatives.

## License and sign-off

The client is licensed under Apache-2.0 (see [LICENSE](LICENSE)).
Contributions are accepted under the Developer Certificate of Origin
(decision 0002); sign your commits off with `git commit -s`. The Wirecopy name
and logo are outside the Apache-2.0 grant.

## What CI checks

The GitHub Actions workflow (`.github/workflows/ci.yml`) runs `swift test`,
builds a universal development bundle, verifies its signature and
architectures, and validates the managed API contract YAML and the Cask
template syntax.
