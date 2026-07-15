# Managed cloud

Managed cloud is the zero-configuration path for users who do not want to
create or maintain object storage. It is also a public hosting service, with
operational and legal responsibilities beyond storing bytes.

## User promise

- Publishing works after account setup without storage credentials.
- Limits and expiration are visible before upload.
- Links can be found, revoked and deleted.
- Default retention is finite on the free plan.
- Upgrading changes limits without changing the shortcut workflow.
- Users can move to S3-compatible storage without learning a different app.

## Data path

The client asks the API for a narrowly scoped upload intent, then uploads
directly to a private object-storage bucket. The client completes the intent and
receives a controlled link. See [Architecture](architecture.md) for the
sequence.

Serving untrusted files uses a dedicated content domain that receives no
application authentication cookies. Risky types should download with a safe
`Content-Disposition` rather than render inline.

## Lifecycle states

```text
created → uploading → available → expired
                    ├───────────→ revoked
                    └───────────→ deleted
```

Abandoned upload intents and incomplete multipart uploads expire quickly.
Object-store lifecycle rules are a backstop; application jobs reconcile link
metadata and object state.

Deletion semantics must explain when an object becomes inaccessible and when
its bytes are expected to be removed from active storage and backups.

## Metering model

Request count alone is a poor limit. Sustainable plans account for:

- bytes uploaded per period;
- active stored bytes and retention duration;
- maximum asset size;
- download bytes or exceptional download abuse;
- upload and download request volume;
- packaging, preview and scanning work;
- number of active controlled links.

The product UI can summarize these simply while billing and abuse systems use
the complete model.

## Initial limit hypotheses

These are experiments, not announced plans.

| Plan | Uploads | Maximum file | Active storage | Default retention |
| --- | ---: | ---: | ---: | --- |
| Free | 5 per day | 25 MB | 1 GB | 24 hours |
| Pro | Fair-use or high cap | 1 GB | 25–50 GB | Configurable |

Limits should be tested against actual developer workflows. A daily upload cap
is easy to understand but cannot replace byte and abuse limits.

## Cost model

Cloudflare R2 is a plausible initial store because its documented pricing is
simple and direct egress does not carry an R2 egress fee. It is not a permanent
product dependency: the storage interface and cost model should permit another
S3-compatible backend.

Planning includes:

- object storage and operations;
- metadata database and edge/API requests;
- malware scanning and file preparation;
- observability, support and transactional email;
- payment fees, taxes, fraud and chargebacks;
- abusive downloads and legal response;
- backups and recovery where applicable.

Current infrastructure figures are recorded in
[Research sources](research-sources.md).

## Account and recovery

Authentication should be low-friction but must support ownership checks for
revocation and deletion. Account deletion requires a clear choice or policy for
active links. Recovery must not depend on an unrecoverable local-only identifier
unless the user explicitly chose an anonymous mode.

An anonymous free tier is not recommended for launch because it weakens quota,
revocation, abuse response and support.

## Service objectives to define before beta

- upload-intent availability and latency;
- success rate by file-size band;
- link resolution availability and latency;
- maximum time from revoke/delete action to inaccessible link;
- lifecycle deletion reconciliation window;
- support and abuse response targets;
- backup, restore and incident communication policy.

Do not promise an SLA until the service has measured production behavior.
