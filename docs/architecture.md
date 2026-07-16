# Architecture

## System shape

Wirecopy has two codebases joined by a versioned managed-service contract:

```text
Public repository                          Private repository
┌──────────────────────────┐              ┌──────────────────────────┐
│ Native Swift/SwiftUI app │              │ Rails 8.1 monolith       │
│ Standalone Swift CLI     │              │ Hotwire web application │
│ Shared publishing model │◀─ OpenAPI ───▶│ JSON API and link host  │
│ BYOS destination adapters│              │ jobs, billing and admin │
└────────────┬─────────────┘              └────────────┬─────────────┘
             │                                         │
             ├── user-owned S3-compatible storage     ├── PostgreSQL
             │                                         └── private R2
             └── managed upload intent ────────────────────────┘
```

The public repository contains `contracts/managed-api-v1.yaml`. The private
service pins an exact public tag or commit, generates or validates its API
types, and fails CI when its implementation is incompatible. Additive changes
remain in v1; breaking changes require a new major contract.

## Native client

The app supports macOS 14 and later as a universal Apple silicon and Intel
build. SwiftUI owns normal application surfaces and AppKit is used where macOS
APIs require it. The app and standalone CLI share Swift packages; the CLI does
not depend on a running GUI application.

| Module | Responsibility |
| --- | --- |
| `InputSource` | Describes pasteboard, Finder or explicit-path input. |
| `InputInspector` | Selects supported representations without mutating the clipboard. |
| `PreparedAsset` | Owns a stable file, MIME type, safe name, size and cleanup. |
| `PublishPolicy` | Captures destination, retention, output and packaging rules. |
| `UploadDestination` | Implements managed intents or an S3-compatible destination. |
| `Publisher` | Coordinates preparation, progress, cancellation and persistence. |
| `PublishedLink` | Records URL, destination, lifecycle and supported actions. |
| `OutputFormatter` | Produces raw URL, Markdown, HTML or structured JSON. |
| `HistoryStore` | Persists non-secret local history in a small versioned database. |

The first official BYOS compatibility matrix is AWS S3, Cloudflare R2,
Backblaze B2 and MinIO. Provider presets compile into one explicit S3
configuration containing endpoint, region, bucket, addressing mode, object
prefix and public-link strategy. Credentials remain in Keychain.

Capability-aware UI is required. A BYOS destination that cannot revoke or
expire a link must not display those actions as though they were supported.

## Managed Rails service

The managed service is a Ruby on Rails 8.1 full-stack monolith with Hotwire,
Turbo and Stimulus. It owns:

- the account, link-management, usage and billing web UI;
- the JSON API used by the official clients;
- managed-link resolution;
- authorization, quotas and lifecycle state;
- Dodo Payments webhooks and subscription reconciliation;
- Solid Queue jobs for scanning, reconciliation, deletion and notifications;
- internal abuse and administration surfaces.

The browser application and JSON API are one deployable application. They do
not need a separate frontend runtime. The initial hostnames are:

| Host | Purpose |
| --- | --- |
| `app.wirecopy.app` | Account and management UI. |
| `api.wirecopy.app` | Client API. |
| `links.wirecopy.app` | Public managed-link resolver. |

Application authentication cookies are host-only and never sent to the public
link host or object-storage origin.

## Managed upload sequence

```text
Mac client            Rails API          Private object store      Scanner
    │                      │                       │                    │
    │─ create intent ─────▶│                       │                    │
    │                      │─ authorize + quota    │                    │
    │◀─ scoped PUT grant ──│                       │                    │
    │──────────────────── direct upload ─────────▶│                    │
    │─ complete intent ───▶│                       │                    │
    │                      │─ verify object ──────▶│                    │
    │                      │──────────────────────── scan request ────▶│
    │◀─ available link ────│◀────────────────────── scan result ───────│
```

Rails never proxies ordinary upload bytes. `UploadIntent` wraps the storage
adapter and issues a short-lived grant limited to one unpredictable key and the
declared size/type constraints that the provider can enforce. Completion is
idempotent and verifies the stored object before it can become available.

The managed lifecycle is:

```text
created → uploading → quarantined → available → expired
                    │             ├────────────→ revoked
                    │             └────────────→ deleted
                    └─────────────→ rejected
```

Malware, scan failures and encrypted archives are rejected in the initial
managed service. Only verified PNG, JPEG, GIF and WebP assets may render inline;
other accepted files use attachment disposition.

## Identity and API authorization

Clerk provides Apple and GitHub sign-in for the web and native onboarding
flow. Rails remains the authorization system of record. A Clerk session is
exchanged for a revocable, scoped Rails device token stored in Keychain.

The standalone CLI uses the same Keychain token when it can share the official
access group. Self-built or differently signed CLIs can use a personal/device
token created in the dashboard instead of depending on the official signing
identity.

The v1 contract includes, at minimum:

- device-token exchange, listing and revocation;
- upload-intent create and complete;
- link list, detail, revoke and delete;
- quota and plan summary;
- managed history synchronization.

Managed history synchronizes through Rails. BYOS history remains local because
the managed service does not receive user-owned destination metadata by
default.

## Link delivery

Managed links use at least 128 bits of entropy and are bearer credentials.
Rails checks expiration, revocation, deletion and abuse state on every request,
records an allowed aggregate access event, and returns a redirect to a
very-short-lived signed R2 GET URL. It does not stream the file through Rails.

The initial release has bearer links only. Passwords and client-side encrypted
links are deferred until their security and recovery protocols are reviewed.

## Local service development

Local Rails development uses a deliberately small Docker Compose file with
only two infrastructure services:

| Service | Purpose | Local behavior |
| --- | --- | --- |
| `db` | PostgreSQL, matching the production adapter | Separate development and test databases in one persistent volume. |
| `minio` | S3-compatible object storage | One private development bucket and one persistent volume. |

Rails runs on the host for fast reloads. PostgreSQL and MinIO ports bind to
`127.0.0.1`, images are pinned, both services have health checks, and example
credentials are development-only values in `.env.example`. No local SQLite
adapter or Homebrew PostgreSQL installation is supported.

The normal commands are:

```bash
docker compose up -d db minio
bin/setup
bin/dev
```

`bin/setup` waits for healthy services, creates and migrates the databases, and
idempotently creates the private MinIO bucket through the same S3 SDK used by
the application. Environment variables select the storage implementation:

- development and local integration tests use the MinIO endpoint with
  path-style addressing;
- deployed environments require `DATABASE_URL` and R2 credentials and endpoint;
- production refuses to boot when required database or object-storage
  credentials are missing.

ClamAV is intentionally not a third default Compose service. Most local tests
use a scanner fake; a small opt-in Compose profile or CI job runs the real
scanner and the EICAR integration test.

The repository-level `./scripts/verify` command owns environment creation,
fixture loading, fault simulation, scenario execution and cleanup. It requires
no interactive provider login. See [Automated testing harness](testing-harness.md).

## Production deployment

Kamal deploys the Rails image to an initial Hetzner VM. Rails web, Solid Queue,
PostgreSQL and an isolated ClamAV container share that host for the first paid
beta. This is a cost-conscious starting topology, not an assertion that the
database will remain colocated indefinitely.

Production storage is a private Cloudflare R2 bucket. PostgreSQL continuously
archives WAL to a separate encrypted R2 backup bucket, creates daily base
backups, retains recovery data for 30 days and is restore-tested weekly. The
internal objectives are a 15-minute recovery point, four-hour recovery time and
99.5% availability; no public SLA is promised.

The deployment region remains configurable until customer evidence determines
the primary geography.

## CLI and distribution contract

The executable is `wirecopy`. Human progress is written to standard error and
pipeable output to standard output. JSON response fields and exit codes are
versioned before integrations depend on them.

```bash
wirecopy publish ./diagram.png --preset quick --format markdown
wirecopy publish --clipboard --json
wirecopy links revoke <id>
```

The signed standalone CLI is bundled with the application in the same Homebrew
Cask. A separate formula is deferred until independent CLI installation proves
useful.

## Build order

1. Native client and CLI against a deterministic fake destination.
2. BYOS adapters and provider contract tests.
3. Rails managed path using local PostgreSQL and MinIO.
4. Dodo billing, production R2, scanning and paid beta operations.

## Deferred decisions

- multipart threshold and resume behavior beyond the initial 250 MB limit;
- password-protected and client-side encrypted links;
- folders, file promises, packages and collection landing pages;
- custom domains, teams and visitor-level analytics;
- optional managed short links for BYOS objects;
- App Store distribution, a separate CLI formula and managed-service
  self-hosting;
- moving PostgreSQL or workers to separate production hosts as measured load or
  failure isolation requires.

The next architecture exploration is atomic publication of an HTML file or
static-site folder to managed R2, followed by capability-aware BYOS modes. It is
specified separately in
[Static-site publishing exploration](static-site-publishing.md) because active
HTML cannot use the ordinary download origin or lifecycle unchanged.
