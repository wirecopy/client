# Managed cloud

Managed cloud is the zero-configuration path for users who do not want to
operate object storage. It is also a public hosting service with security,
abuse, recovery and legal responsibilities beyond storing bytes.

## User promise

- Publishing works after account setup without storage credentials.
- Limits and expiration are visible before upload.
- Links can be found, revoked and deleted.
- Default retention is finite.
- Upgrading changes limits without changing the shortcut workflow.
- Users can move to S3-compatible storage without learning another app.

## Service implementation

The service is one Rails 8.1 application using Hotwire for the web UI,
PostgreSQL for authoritative metadata and Solid Queue for background work.
Clerk provides Apple and GitHub sign-in; Rails issues and authorizes its own
revocable device tokens. Dodo Payments is the merchant-of-record billing
provider and Rails derives entitlements from verified, idempotently processed
webhooks.

Cloudflare R2 is the production object store. The storage boundary remains
S3-compatible so development can use MinIO and a future migration does not
rewrite product lifecycle logic.

See [Architecture](architecture.md) for repository boundaries, hostnames,
upload sequencing, local development and deployment.

## Data path and link delivery

The client asks Rails for a narrowly scoped upload intent, uploads directly to
a private R2 key, and completes the intent. Rails verifies the object, moves the
record into quarantine and activates a controlled link only after a clean
ClamAV verdict. Rails does not proxy ordinary upload or download bytes.

For an allowed request, `links.wirecopy.app` enforces lifecycle and abuse state,
then redirects to a very-short-lived signed R2 GET URL. The R2 origin receives
no application cookies. The signed URL lifetime bounds the delay between a
revoke/delete action and the loss of access for a URL that was already resolved.

Only verified PNG, JPEG, GIF and WebP assets render inline initially. Other
accepted file types are served as downloads with safe content headers.

## Lifecycle states

```text
created → uploading → quarantined → available → expired
                    │             ├────────────→ revoked
                    │             └────────────→ deleted
                    └─────────────→ rejected
```

- An object is unreachable while uploading or quarantined.
- Malware, encrypted archives, scan failures and exhausted scan retries end in
  `rejected`; production fails closed when scanning is unavailable.
- Abandoned intents, rejected objects and incomplete uploads are purged by
  reconciled jobs and object-store lifecycle rules.
- Completion, revocation, deletion and reconciliation are idempotent.

The initial product uses high-entropy bearer links. Password protection and
client-side encryption are not launch capabilities.

## Plans and limits

These are accepted beta limits, not merely pricing-page copy. Enforcement must
cover both understandable plan limits and internal abuse thresholds.

| Plan | Price | Uploads | Maximum file | Active storage | Default retention | Maximum retention |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| Free | $0 | 5 per day | 25 MB | 1 GB | 24 hours | 24 hours |
| Pro | $7/month | High cap with abuse controls | 250 MB | 25 GB | 30 days | 1 year |

Downloads remain subject to non-marketed abuse and cost controls. The UI must
show current usage and the exact reason an upload is rejected. Custom domains,
teams and higher limits are later product decisions rather than implied Pro
features.

## Metering and customer analytics

Mandatory service metering is limited to what is needed for quotas, billing,
security, reliability and abuse response. Customer-facing analytics initially
show aggregate per-link access count and last access time.

An access is counted when Rails allows a public link resolution. Automated
requests, retries and range behavior require documented normalization before
the metric is presented as a download count. Brief IP address and user-agent
data may be retained for abuse detection for at most 30 days; it is not exposed
as visitor identity to the link owner.

The service does not collect filenames, URLs, clipboard contents, object keys
or credentials as product telemetry. Optional client diagnostics are separately
opted in through settings, retain only minimal failure and performance events
for 30 days, and never turn local/BYOS history into managed analytics.

## Account deletion

Account deletion immediately:

- revokes every Rails device token and controlled link;
- rejects new intents and cancels incomplete uploads/scans;
- ends the managed entitlement and starts provider cleanup;
- schedules active and quarantined objects for purge within 24 hours.

Rails account data and customer-visible analytics are deleted or irreversibly
disassociated as required by the data inventory. Recovery backups expire within
30 days and must not reactivate links or tokens if restored. Deletion is an
idempotent workflow with reconciliation for partial Clerk, Dodo, PostgreSQL or
R2 failures.

## Operations and recovery

Kamal deploys the initial service to a Hetzner VM running Rails web, Solid
Queue, PostgreSQL and isolated ClamAV containers. A separate encrypted R2
bucket receives continuous PostgreSQL WAL archives and daily base backups.

- Recovery point objective: 15 minutes.
- Recovery time objective: 4 hours.
- Backup retention: 30 days.
- Restore drill: weekly into an isolated environment.
- Internal availability objective: 99.5%.
- Public SLA: none during the initial service.

R2 object durability is not a substitute for PostgreSQL recovery, and database
backups are not a copy of managed file objects. The runbook must state the
accepted object-loss boundary and test lifecycle consistency after restoration.

## Cost model

Planning includes:

- R2 storage and operations;
- PostgreSQL, Rails and link-resolution compute;
- ClamAV scanning and quarantine work;
- observability, support and transactional email;
- Dodo payment fees, taxes, fraud and chargebacks;
- abusive downloads, takedowns and legal response;
- backup storage and restore drills.

Current external figures belong in [Research sources](research-sources.md) and
must be rechecked before financial or public claims.

## Pre-beta service objectives

- upload-intent and link-resolution latency/error objectives measured;
- revoke/delete propagation no longer than the signed GET URL lifetime;
- lifecycle deletion reconciliation within the promised windows;
- scanner signatures, scanner health and fail-closed behavior monitored;
- abuse reporting and response runbooks exercised;
- backup alerts and weekly restore evidence retained;
- account-deletion workflow tested across all providers.
