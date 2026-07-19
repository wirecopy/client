# Security and abuse

Public file hosting changes the threat model. Security, lifecycle and abuse
controls are release requirements for managed cloud, not later enhancements.

This document is a product security baseline, not a completed threat model or
legal review.

## Trust boundaries

- The Mac client handles local files, pasteboard contents, Keychain credentials
  and a scoped Rails device token.
- Clerk authenticates account sign-in; Rails independently authorizes every API
  operation and owns device-token revocation.
- The Rails service owns upload intent, quota, link and lifecycle state in
  PostgreSQL.
- Private R2 stores untrusted bytes; local development substitutes MinIO.
- Isolated ClamAV workers read quarantined content and return a verdict.
- The public link host accepts bearer tokens and redirects allowed requests to
  short-lived signed object URLs.
- Dodo Payments processes checkout and subscription state as merchant of record.
- BYOS destinations may be entirely outside the managed service.

Each boundary requires documented inputs, authentication, logging, data
retention and failure behavior.

## Client requirements

- Store native-app S3 credentials and Rails device tokens in Keychain. The npm
  CLI stores only a device token in a user-only configuration file and accepts
  `WIRECOPY_TOKEN` for ephemeral CI runners.
- Never log secrets, raw authorization headers, bearer links, object keys or
  signed URL query strings.
- Refuse plaintext remote endpoints, cross-origin redirects and insecure upload
  grants. Permit HTTP only for loopback development.
- Bound temporary disk use and remove prepared files after completion/failure.
- Detect source-file changes during upload when practical.
- Require explicit consent for Accessibility-driven auto-insert.
- Sign and notarize releases; publish checksums for release archives.
- Treat Homebrew as the update mechanism for Cask installations; the app may
  notify but must not replace a Cask-managed installation itself.

## Authentication and device authorization

Clerk sessions bootstrap device authorization; they are not permanent API
credentials. Rails verifies issuer, audience, signature, time claims and account
mapping, then issues a scoped random token whose plaintext is shown only once.
Rails stores a digest; the Mac stores the token in Keychain.

Users can list, name and revoke devices. Logout, lost-device response and
account deletion revoke the relevant tokens immediately. Every intent, link,
quota and analytics endpoint has cross-account authorization tests. Clerk and
Dodo webhooks require signature verification, replay resistance and idempotent
handling.

## Upload grants

Managed upload grants are:

- short-lived, single-purpose and scoped to one unpredictable object key;
- limited to one upload method and unable to list, read or overwrite unrelated
  objects;
- constrained by quota and expected size before issue;
- verified with trusted object metadata after upload;
- recorded as an intent that can be reconciled;
- safely retryable without multiplying public links.

The service tests completion before upload, duplicate completion, stale grants,
replay, wrong key/size/type/checksum, clock skew and orphan cleanup. The client
never receives managed R2 credentials, and Rails does not proxy normal bytes.

## Quarantine and malware scanning

Completing an upload moves it into quarantine, never directly to availability.
An isolated ClamAV container scans the full object. Production fails closed when
the scanner is unavailable, times out, returns malformed output or has
unacceptable signature freshness.

The initial service rejects malware, encrypted archives and exhausted scan
errors. Archive depth, extracted-size and scan-time limits must prevent archive
bombs. Scan jobs are idempotent across retries and worker termination. Stored
scan metadata contains the verdict, engine/signature version and time, not file
content.

Local development keeps PostgreSQL and MinIO as the only default Compose
services. A scanner fake covers ordinary tests; an opt-in ClamAV profile and CI
job must cover clean files, EICAR, timeout and scanner-down behavior. A deployed
environment must refuse to boot with scanning bypass enabled.

## Link security and delivery

- Use at least 128 bits of entropy in non-sequential managed bearer tokens.
- Keep objects private and enforce `available`, expiration, revocation, deletion
  and abuse state for every resolution.
- Return a very-short-lived R2 GET URL only after an allowed resolution.
- Keep the signed GET lifetime within the documented revoke propagation target.
- Do not put link tokens in ordinary logs, telemetry, referrers or error reports.
- Isolate application cookies from `links.wirecopy.app` and the R2 origin.
- Apply safe content type, `nosniff`, disposition, cache and referrer headers.
- Render inline only the reviewed image allowlist; force HTML, SVG, unknown and
  other active formats to download.

Invalid, quarantined and unavailable tokens return responses that do not make
enumeration easier. Browser tests verify cookie isolation and safe handling of
polyglot and active content.

The initial product does not offer passwords or client-side encrypted links.
Before either is promised, specify and independently review password hashing,
attempt limiting, encryption framing, key handling, streaming integrity,
metadata leakage, recovery and the loss of server-side scanning.

## Abuse controls

The managed service uses layered controls:

- authenticated accounts for uploads;
- per-account and per-network request and byte limits;
- explicit size, type and archive policies;
- quarantine and fail-closed malware scanning;
- abnormal download detection and response;
- a report-abuse path attached to every hosted link;
- takedown, appeal, repeat-abuser and law-enforcement procedures;
- deletion and evidence-preservation rules;
- payment fraud and disposable-account defenses.

Do not promise unlimited uploads, permanent free hosting or unrestricted
anonymous accounts.

## Analytics and privacy

Separate four data classes:

1. local app state and BYOS history, which remain on the Mac;
2. optional diagnostic telemetry, explicitly enabled in settings and retained
   for at most 30 days;
3. mandatory managed-service quota, billing, reliability and abuse records;
4. customer-visible aggregate link access count and last-access time.

Optional diagnostics contain minimal failure and performance events and exclude
filenames, URLs, clipboard contents, object keys and credentials. Brief IP and
user-agent records used for managed-service abuse defense expire within 30 days
and are not exposed to customers as visitor identity. The privacy inventory
must match actual Rails, Clerk, Dodo, R2 and ClamAV flows.

## Account deletion and recovery

Account deletion immediately revokes links and all Rails device tokens, blocks
new uploads, cancels incomplete workflows and schedules active/quarantined R2
objects for deletion within 24 hours. Partial provider failures are retried and
reconciled.

PostgreSQL WAL and daily base backups are encrypted, stored in a separate R2
bucket and expire within 30 days. Weekly isolated restores must demonstrate the
15-minute RPO and four-hour RTO. Restores must not reactivate deleted, revoked or
expired links or tokens, and must preserve deletion tombstones long enough to
prevent resurrection.

## BYOS boundaries

- Credentials remain on the user's Mac unless a separately disclosed service
  requires them.
- The app requests the smallest practical permission set.
- Public-bucket and signed-link behavior remain visibly distinct.
- Deleting local history does not imply that a remote object was deleted.
- Remote deletion failures remain visible and retryable.
- Custom endpoints are untrusted network destinations.
- Revocation and expiration controls appear only when the destination supports
  them.

## Pre-beta security gates

- structured threat model reviewed with no unresolved critical findings;
- dependency, license and secret scanning in CI;
- Clerk verification, device-token lifecycle and cross-account authorization
  suites passing;
- R2 and MinIO upload-grant conformance tests passing;
- quarantine, EICAR, scanner-down and archive-limit tests passing;
- bearer entropy, lifecycle, cookie-isolation and content-header browser tests
  passing;
- account deletion exercised across Rails, Clerk, Dodo and R2;
- analytics data inventory and retention verified against real logs/events;
- abuse, malware and takedown runbooks exercised;
- weekly restore evidence meets the RPO/RTO;
- independent review completed before password or encryption work ships.

## Future active-site hosting boundary

Publishing an HTML file as a rendered site is categorically different from
forcing it to download. Owner-supplied JavaScript must run on a separate
registrable domain with per-site origin isolation, no Wirecopy cookies and no
privileged API CORS. ClamAV does not make arbitrary JavaScript trustworthy.
Phishing detection, domain reputation, takedown and service-worker/browser-state
isolation are required before the
[static-site publishing exploration](static-site-publishing.md) can become a
product capability.
