# Automated testing harness

Wirecopy requires a non-interactive verification harness in both repositories.
It must create its own disposable environment, exercise realistic workflows and
produce evidence that a human or CI system can inspect. Manual clicking is an
exploratory supplement, not a release gate.

## Required entry points

Each repository exposes one stable command:

```bash
./scripts/verify
```

The command has no prompts, does not open interactive authentication or payment
pages, and returns a nonzero exit code on any failed gate. It supports:

| Mode | Purpose | External credentials |
| --- | --- | --- |
| default | Fast lint, unit, contract and local integration checks | None |
| `--full` | Disposable end-to-end environment including real ClamAV | None |
| `--release` | Provider conformance, packaging and release evidence | CI secrets only |

`--release` remains non-interactive: missing required CI credentials causes a
clear failure or an explicitly reported skip according to the release policy.
It never pauses to ask a person to log in.

## Disposable managed-service environment

The harness creates a unique Docker Compose project and temporary directories
for every run. Its default infrastructure is the same small local stack used by
developers:

- PostgreSQL with fresh development/test databases;
- MinIO with an isolated private bucket;
- Rails started in test mode by the harness.

Full mode adds an isolated ClamAV service. The harness waits on health checks,
runs migrations, creates buckets, loads deterministic fixtures, starts the
application on loopback, runs scenarios and removes containers, networks,
volumes and temporary assets on success or failure. A `--keep` diagnostic flag
may preserve artifacts, but is never the CI default.

Guardrails reject production hostnames, production credentials and non-test
database names. Generated bucket, database and account names include the run ID
so concurrent jobs cannot collide.

## Simulated external systems

Deterministic local simulators replace services that would otherwise require a
human or create external state:

| Dependency | Harness behavior |
| --- | --- |
| Clerk | Local OIDC/JWKS fixture issues valid, expired, wrong-audience and rotated-key tokens. |
| Dodo Payments | Signed webhook fixture server emits checkout, renewal, failure, replay, cancellation and refund events. |
| Object storage | MinIO exercises S3 operations; fault adapter injects timeout, stale grant, wrong metadata and deletion failures. |
| Malware scanner | Fast fake returns clean/infected/error; full mode verifies the same contract with ClamAV and EICAR. |
| Time | Injectable clock advances intent expiry, retention, signed-URL and backup/deletion windows without sleeping. |
| Network | Client and service adapters inject offline, slow, retry, cancellation and interrupted-upload behavior. |

Simulators implement the same boundary interfaces as production dependencies.
They do not add test-only branches to product lifecycle rules.

## Deterministic fixture corpus

Fixtures are generated or stored with documented licenses and checksums:

- small PNG and JPEG clipboard images;
- a normal Finder file and a deterministic multi-file ZIP result;
- PDF and unknown binary content that must download rather than render inline;
- HTML, SVG and polyglot samples for content-disposition tests;
- zero-byte, exact-limit and over-limit assets;
- EICAR, encrypted archive and bounded nested-archive samples;
- changed-during-upload and interrupted-upload inputs;
- filenames containing Unicode, control characters and path-like segments.

No fixture contains a real credential, personal file or production bearer link.

## Scenario suites

### Native client and CLI

- deterministic pasteboard representation selection;
- single file and deterministic multi-file ZIP preparation;
- fake, MinIO/BYOS and managed destination contracts;
- original clipboard preservation on failure;
- progress, cancellation, retry and temporary-file cleanup;
- raw, Markdown, HTML and JSON formatting;
- CLI stdout/stderr separation, exit codes and schema snapshots;
- Keychain abstraction and dashboard-token fallback for self-built CLIs;
- macOS 14+ tests on Apple silicon and Intel runners where available.

Native UI automation uses a launch argument that selects fake dependencies and
pre-seeded state. It must not require Accessibility permission, notifications or
real account login to verify core screens.

### Managed service

- Clerk bootstrap and Rails device-token issuance/revocation;
- Free and Pro quota boundaries;
- intent creation, scoped PUT, completion and object verification;
- quarantine clean, infected, scanner-down and retry-exhausted paths;
- bearer resolution, aggregate access metrics, expiry, revoke and delete;
- safe inline allowlist and forced download for active/unknown content;
- Dodo webhook verification, replay and entitlement reconciliation;
- account deletion across tokens, links, pending scans and objects;
- diagnostics and log-redaction assertions;
- concurrent requests and idempotency for every mutation.

### Contract and provider conformance

- OpenAPI linting, generated-client drift and backward-compatibility checks;
- private service conformance to the exact public contract revision;
- BYOS matrix tests for AWS S3, Cloudflare R2, Backblaze B2 and MinIO;
- real R2 managed-storage smoke tests in release CI using an isolated bucket;
- no provider test runs against an unscoped or production bucket.

### Recovery and operations

- database migration from the last released schema and rollback policy checks;
- PostgreSQL base-backup/WAL restore into an isolated environment;
- restored state does not reactivate revoked, expired or deleted links/tokens;
- account deletion and object reconciliation survive injected provider failures;
- Kamal configuration renders with required secrets and health checks;
- Homebrew Cask install, upgrade and uninstall on clean macOS CI.
- npm CLI install and `npx` execution on macOS, Linux and Windows CI.

### Static-site exploration

- single HTML and folder-manifest deployment to MinIO/R2;
- atomic activation with no partially visible site;
- index, nested-asset, MIME, 404 and cache behavior in a real browser;
- traversal, symlink, case-collision and Unicode-path rejection;
- per-site cookie, storage, service-worker and CORS isolation;
- active JavaScript confined to a non-Wirecopy registrable domain;
- BYOS capability detection that never labels a raw object base URL a website.

The service's opt-in `script/live-site-smoke` tracer covers managed R2 without
persisting credentials or fixtures. It publishes a single HTML file, an
enclosing-folder ZIP and browser-style folder files; fetches HTML, CSS and
JavaScript from distinct per-site origins; verifies status, MIME and marker
bytes; and cleans up both activation descriptors and immutable prefixes in an
`ensure` block. The 2026-07-17 run used a disposable `wirecopy.app` wildcard
only to validate mechanics. Production evidence must use the separately
registered artifact domain required by decision 0009.

## Machine-readable evidence

Every run writes an artifact directory containing:

- a JSON manifest with commit, contract version, tool/image versions, random
  seed, environment mode and scenario totals;
- JUnit XML for test results;
- coverage reports for the Swift and Rails codebases;
- OpenAPI compatibility output;
- redacted service logs and failed-scenario diagnostics;
- release-mode provider, restore and packaging reports.

Secrets, bearer URLs, filenames from user input and signed query strings are
redacted before artifacts are persisted. A concise terminal summary links each
failed scenario to its evidence.

## CI and release gates

Pull requests run default mode in both repositories. The service repository also
checks out the pinned public contract revision. Scheduled and release workflows
run full mode, the real-provider matrix and recovery scenarios.

A release is blocked unless:

- both repositories pass their pinned contract checks;
- no required suite is skipped;
- the managed lifecycle passes from intent through quarantine, availability,
  resolution and revocation/deletion;
- security, log-redaction and account-deletion assertions pass;
- the restore report meets the documented RPO/RTO;
- the signed/notarized Cask and npm CLI pass their clean-machine tests.

Flaky tests are failures to fix, not tests to retry until green. The harness may
rerun a failed scenario only to collect diagnostics and must preserve the first
failure in its report.
