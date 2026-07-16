# 0006: Set the initial managed-cloud plans and lifecycle policy

- Status: Accepted for beta validation
- Date: 2026-07-16

## Context

The managed beta needs explicit limits, lifecycle and privacy behavior before
billing or public hosting can be implemented. Leaving these as “fair use” would
make quota UX, unit economics, deletion promises and security tests
indeterminate.

## Decision

Offer Free and Pro managed plans:

| Plan | Price | Uploads | Maximum file | Active storage | Default retention | Maximum retention |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| Free | $0 | 5/day | 25 MB | 1 GB | 24 hours | 24 hours |
| Pro | $7/month | High cap with abuse controls | 250 MB | 25 GB | 30 days | 1 year |

Use high-entropy bearer links only. Managed uploads move through quarantine and
become available only after a clean ClamAV verdict. Malware, encrypted archives
and exhausted scanning failures are rejected. Rails authorizes every link
resolution and redirects an allowed request to a very-short-lived signed R2 GET
URL.

Customer analytics initially contain only aggregate per-link access count and
last-access time. Brief IP and user-agent data may be retained for abuse defense
for at most 30 days and is never exposed as visitor identity. Client diagnostic
telemetry is settings opt-in, minimal, retained for at most 30 days and excludes
filenames, URLs, clipboard contents, object keys and credentials.

Account deletion immediately revokes tokens and links, purges active objects
within 24 hours and ages recovery backups out within 30 days.

## Consequences

### Positive

- Quota, billing, retention and deletion have testable semantics.
- A low free limit permits product discovery without implying anonymous or
  permanent hosting.
- The $7 plan is simple enough to test willingness to pay.
- Aggregate analytics provide operational value without visitor surveillance.

### Negative

- A 250 MB ceiling excludes some media workflows.
- Bearer links cannot provide password challenges or recipient identity.
- Fail-closed scanning rejects some legitimate encrypted archives.
- Download-abuse thresholds and Pro upload cap remain internal rather than a
  simple marketed number.

## Revisit when

- observed storage, download or support costs invalidate plan economics;
- customers regularly hit a limit in legitimate target workflows;
- password or encrypted-link protocols complete security review;
- abuse patterns require different retention or file policies;
- the privacy inventory shows aggregate metrics cannot be implemented as stated.
