# Security and abuse

Public file hosting changes the threat model. Security, lifecycle and abuse
controls are release requirements for managed cloud, not later enhancements.

This document is a product security baseline, not a completed threat model or
legal review.

## Trust boundaries

- The Mac client handles local files, pasteboard contents and user credentials.
- The application API authenticates accounts and authorizes upload/link actions.
- Object storage holds untrusted user-controlled bytes.
- The public content domain serves requests from unauthenticated recipients.
- Payment, email and scanning vendors receive specifically inventoried data.
- S3-compatible destinations may be entirely outside the managed service.

Each boundary needs documented inputs, authentication, logging and retention.

## Client requirements

- Store S3 credentials, service tokens and encryption keys in Keychain.
- Never include secrets, raw Authorization headers or signed URL query strings
  in ordinary logs.
- Validate endpoint schemes and explain custom certificate failures.
- Bound temporary disk use and remove prepared files after completion/failure.
- Detect source-file changes while uploading when practical.
- Require explicit consent before enabling Accessibility-driven auto-insert.
- Sign and notarize releases; publish checksums for direct downloads.
- Design automatic updates with signature verification and rollback behavior.

## Upload authorization

Managed upload grants should be:

- short-lived;
- single-purpose and scoped to one unpredictable object key;
- constrained by account quota and expected size;
- unusable for listing, reading or overwriting unrelated objects;
- recorded as an intent that can be reconciled;
- safely retryable without multiplying public links.

Do not trust client-declared MIME type, file extension or successful completion.
Verify object existence and size before activating a link.

## Link security

- Use high-entropy, non-sequential public identifiers.
- Keep managed objects private; authorize access at the link service.
- Enforce expiration, revocation and deletion for every request.
- Hash passwords using an appropriate password-hashing function.
- Rate-limit password attempts and high-volume enumeration patterns.
- Avoid leaking private filenames in URLs unless the user chooses that behavior.
- Serve content on a domain isolated from application cookies and privileged
  browser capabilities.
- Set safe content type, sniffing and disposition headers.

Presigned S3 URLs are bearer credentials. Their query values must be treated as
secrets until expiration and their maximum lifetime communicated to the user.

## Abuse controls

The service needs layered controls:

- authenticated accounts for managed uploads;
- per-account and per-network rate and byte limits;
- size/type policies and archive handling rules;
- malware detection appropriate to the privacy mode;
- automated response to abnormal download traffic;
- a report-abuse path attached to hosted links;
- takedown, appeal, repeat-abuser and law-enforcement procedures;
- deletion and evidence-preservation rules;
- payment fraud and disposable-account defenses.

Avoid promising unlimited uploads, permanent free hosting or unrestricted
anonymous accounts.

## Privacy modes

### Standard managed link

The service can inspect enough metadata/content to enforce policy and optionally
produce previews. The privacy notice must enumerate collection and retention.

### Client-side encrypted link

The client encrypts content before upload and places the decryption secret in
the URL fragment so it is not sent to the server during a normal request.
Before offering this mode, specify and review:

- algorithms, versioning and authenticated-encryption framing;
- key generation and encoding;
- large-file streaming and integrity behavior;
- recipient browser implementation;
- filename and metadata leakage;
- password interaction and recovery expectations;
- inability to perform server-side preview or content scanning;
- abuse response for opaque content;
- link forwarding and referrer behavior.

“Encrypted” must not be used in product copy until this protocol is implemented,
tested and reviewed.

## BYOS boundaries

For user-owned S3-compatible storage:

- credentials remain on the user's Mac unless a separately disclosed service
  requires them;
- the app should request the smallest practical permission set;
- public-bucket configuration and signed-link behavior are clearly distinguished;
- deleting local history must not imply that the remote object was deleted;
- remote deletion failures remain visible and retryable;
- custom endpoints are untrusted network destinations.

## Pre-beta security gates

- structured threat model reviewed;
- dependency and secret scanning in CI;
- authentication and authorization tests for every link mutation;
- upload-grant scope tests;
- content-domain isolation verified in a browser;
- lifecycle and deletion reconciliation tests;
- log redaction tests;
- malware/abuse handling runbook exercised;
- privacy data inventory and retention schedule published;
- independent security review for encryption or password-protected links.
