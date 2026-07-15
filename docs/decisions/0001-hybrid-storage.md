# 0001: Support managed and user-owned storage

- Status: Accepted for product research
- Date: 2026-07-15

## Context

The product needs a low-friction path for users who do not operate storage and
an ownership path for technical users who already use S3-compatible services.
A managed-only product introduces lock-in concerns; a BYOS-only product makes
first value depend on acquiring and correctly configuring infrastructure.

Direct competitors demonstrate that both modes are feasible and that offering
both is not itself a unique differentiator.

## Decision

Model managed cloud and S3-compatible bring-your-own storage as destinations
behind one publishing workflow.

- Managed cloud is the zero-configuration default.
- BYOS stores credentials locally in Keychain and uploads directly from the Mac.
- Entry points, policy presets, output formatting and local history use a shared
  domain model.
- Managed uploads go directly to private object storage through scoped upload
  grants; the API does not proxy ordinary file bytes.
- The product position remains the developer publishing command, not “hybrid
  storage.”

## Consequences

### Positive

- New users can reach first value without learning S3.
- Technical users can retain storage ownership and custom infrastructure.
- The app can serve free/local and recurring-hosted business models.
- A shared workflow can make migration between destinations understandable.

### Negative

- Two destination paths increase testing and support scope.
- BYOS compatibility has provider-specific edge cases despite an S3 interface.
- Managed cloud requires billing, abuse response, lifecycle and legal operations.
- Link capabilities differ: a raw public object URL cannot always be revoked in
  the same way as a managed redirect.

## Revisit when

- user research shows one mode has negligible demand;
- implementation forces materially inconsistent workflows;
- managed economics or abuse controls are not sustainable;
- App Store or platform constraints prevent secure BYOS configuration;
- the product selects a narrower initial release sequence without abandoning the
  shared destination model.
