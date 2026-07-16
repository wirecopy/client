# 0002: Open-source the client and CLI

- Status: Accepted for implementation
- Date: 2026-07-15

## Context

The Mac client handles clipboard contents, local files and credentials for
user-owned storage. The initial audience is developers, who benefit from being
able to inspect security-sensitive behavior, build integrations and contribute
storage or output adapters.

The business also needs a sustainable source of revenue. Charging for arbitrary
client-side restrictions would conflict with an open client and weaken the
promise that bring-your-own storage is a first-class workflow. Managed cloud,
by contrast, provides ongoing storage, controlled-link enforcement, security,
abuse response and support that create recurring costs and value.

## Decision

Publish the source for the native Mac client, CLI, shared publishing model and
bring-your-own S3-compatible integrations under the Apache License 2.0.

- Keep the core local and BYOS workflow fully usable without a paid client
  license.
- Publish stable CLI and service contracts so integrations do not depend on UI
  automation or undocumented behavior.
- Distribute official signed and notarized builds through the Homebrew Cask.
- Monetize the managed cloud service rather than gating arbitrary capabilities
  in the open client.
- Do not promise a supported self-hosted managed service merely because client
  and protocol source is available.
- Keep the managed-service implementation private. Publishing it later would
  require a separate decision and is not implied by the public API contract.
- Keep the public client in one repository and the private Rails service in a
  second repository.
- Publish the managed API's OpenAPI contract with the client. The private
  service pins the exact public contract revision and verifies compatibility in
  CI.
- Accept contributions under a Developer Certificate of Origin. Keep the
  Wirecopy name and logo outside the Apache-2.0 license and document the
  trademark boundary before accepting public contributions.

The public protocol permits alternative clients. It does not promise that the
private hosted service can be self-hosted.

## Consequences

### Positive

- Users can inspect how clipboard contents, local files and credentials are
  handled.
- Developers can add integrations and storage destinations without waiting for
  the core team.
- Free BYOS distribution can grow adoption without creating hosted storage
  costs.
- Revenue aligns with the continuing cost and convenience of managed hosting.
- Official builds can remain signed, notarized and easy to install even though
  their source is public.

### Negative

- A one-time paid Mac Pro tier is no longer the primary business-model
  hypothesis.
- Competitors can study or reuse implementation ideas within the selected
  license's terms.
- Public contribution and release processes add maintenance and security
  disclosure work.
- Keeping the service private means the product must describe its open-source
  scope precisely and avoid implying that the entire hosted system is open or
  supported for self-hosting.

## Alternatives considered

### Closed client with a one-time license

This could monetize BYOS users directly, but provides less assurance around
credential and clipboard handling and makes ecosystem contributions harder.

### Open-source client and managed backend at launch

This maximizes inspectability, but publishing backend code can be confused with
a supported self-hosting commitment before deployment, migration, abuse and
security operations are stable.

### Open core with paid client features

This preserves client revenue but risks manufacturing limitations in the core
publishing workflow. Managed-service value is a cleaner initial paid boundary.

## Revisit when

- users demonstrate meaningful demand for supported self-hosting;
- managed-cloud revenue cannot sustain client development;
- the contribution model creates more maintenance cost than ecosystem value.
