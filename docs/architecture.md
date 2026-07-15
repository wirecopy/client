# Architecture

## System shape

```text
Clipboard / Finder / Share / CLI
              │
              ▼
       Native input adapters
              │
              ▼
       Publishing service
        ├─ policy resolver
        ├─ file preparation
        ├─ destination
        └─ output formatter
              │
       ┌──────┴────────┐
       ▼               ▼
 Managed destination  S3-compatible destination
       │               │
       ▼               ▼
 Short controlled URL  public or signed object URL
              │
              ▼
       Clipboard / JSON result
```

The native app, extensions and CLI share domain models. Platform adapters may
differ, but input preparation, policy validation, destination behavior and
result formatting should not be reimplemented per entry point.

## Proposed native modules

| Module | Responsibility |
| --- | --- |
| `InputSource` | Describes pasteboard, Finder, Share extension, dropped or explicit-path input. |
| `InputInspector` | Selects supported representations and rejects unsupported input without mutation. |
| `PreparedAsset` | Represents a stable file, MIME type, safe name, size and cleanup ownership. |
| `PublishPolicy` | Captures destination, retention, access mode, output format and packaging rules. |
| `UploadDestination` | Validates configuration, creates upload grants or signs S3 requests, and completes publication. |
| `Publisher` | Coordinates preparation, progress, cancellation, upload and result persistence. |
| `PublishedLink` | Stores URL, object identity, lifecycle, destination and available actions. |
| `OutputFormatter` | Produces raw, Markdown, HTML or structured results. |
| `HistoryStore` | Persists non-secret link metadata and revocation/deletion state. |

Swift protocols should define boundaries where multiple implementations exist.
Avoid layers whose only purpose is to mirror these names.

## Managed upload sequence

```text
Mac client                API                 Object storage
    │                      │                        │
    │─ create intent ─────▶│                        │
    │                      │─ authorize + quota     │
    │◀─ scoped PUT grant ──│                        │
    │──────────────────── direct upload ───────────▶│
    │─ complete intent ───▶│                        │
    │                      │─ verify object ───────▶│
    │◀─ controlled link ───│                        │
```

The API does not proxy ordinary file bytes. An upload grant is short-lived,
limited to one object key and constrained by expected content length/type where
the provider supports it. Completion is idempotent.

## S3-compatible upload sequence

The Mac signs and sends the upload directly using credentials stored in
Keychain. Configuration includes endpoint, region/signing scope, bucket,
optional account/tenant ID, path-style behavior, object prefix and public-link
strategy.

Provider-specific presets may fill defaults but should compile into one
validated S3 destination configuration. Do not silently combine partial
credential namespaces or fall back between profiles; a selected profile is
complete or fails loudly.

Supported URL strategies:

- public base URL plus object key;
- temporary presigned GET URL;
- custom link service, if explicitly configured.

The application must explain that an S3 API endpoint is not necessarily a
public website. A valid upload does not prove anonymous download access.

## Link model

A managed link points to an application-controlled identifier rather than the
raw storage key. The link record can include:

- owner and destination;
- object identifier and content type;
- original display name and size;
- created, expires, revoked and deleted timestamps;
- access policy and optional password verifier;
- download counters or abuse flags when the privacy policy permits them;
- checksum and upload completion state.

Redirect or download services must enforce the record state on every request.
Short IDs require enough entropy to resist enumeration.

## Local persistence

- Secrets and access tokens: Keychain.
- Preferences and non-secret presets: application settings store.
- Recent-link metadata: a small versioned database.
- Prepared temporary assets: protected cache with explicit ownership and
  restart cleanup.
- Diagnostic logs: bounded, redacted and user-exportable.

URLs can contain credentials or signatures. Logs must redact query strings by
default.

## CLI contract

A future command shape might be:

```bash
ctl publish ./diagram.png --preset quick --format markdown
ctl publish --clipboard --json
ctl links revoke <id>
ctl links delete <id>
```

The executable name is unresolved. Exit codes and JSON fields must be versioned
before integrations depend on them. Human-readable progress goes to standard
error so standard output remains pipeable.

## Reliability requirements

- cancellation propagates to preparation and network tasks;
- retries never create an uncontrolled second public object;
- completion and deletion operations are idempotent;
- the original clipboard is preserved until a link is ready;
- a failed link-formatting step does not orphan an unknown object;
- lifecycle status reconciles after offline periods;
- clocks and upload expiration are handled explicitly;
- tests cover interrupted uploads, app termination and stale grants.

## Open architecture decisions

- whether the CLI embeds upload logic or talks to the running app;
- the managed identity and billing provider;
- redirect edge runtime and metadata store;
- multipart upload threshold and resume behavior;
- encrypted-link protocol and its impact on scanning/previews;
- history synchronization between Macs;
- whether BYOS can optionally use managed short links without transferring file
  ownership.
