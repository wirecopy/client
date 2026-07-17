# 0004: Build the managed service as a Rails monolith

- Status: Accepted for implementation
- Date: 2026-07-16

## Context

Wirecopy needs an authenticated dashboard, native-client API, controlled-link
resolver, subscription handling, background lifecycle jobs and internal abuse
tools. Splitting those responsibilities across a JavaScript frontend, separate
API and edge functions would create more deployment and contract surface before
the product has validated demand.

The native client must still upload directly to object storage. Choosing a Rails
monolith does not authorize proxying ordinary file bytes through the service.

## Decision

Build the private managed service as a Ruby on Rails 8.1 full-stack monolith.

- Use Hotwire, Turbo and Stimulus for the account, analytics, billing and admin
  UI.
- Use PostgreSQL as the authoritative metadata store and Solid Queue for jobs.
- Use Clerk for authentication. The initial production launch uses email
  verification codes; Apple and GitHub are deferred by
  [decision 0011](0011-email-code-launch-authentication.md). Rails exchanges a
  verified Clerk session for its own revocable, scoped device token and remains
  the authorization system of record.
- Use Dodo Payments as merchant of record. Verified, idempotently processed
  webhooks determine subscription entitlement.
- Use private Cloudflare R2 for managed objects behind an S3-compatible storage
  boundary.
- Deploy initially with Kamal to a Hetzner VM containing Rails web, Solid Queue,
  PostgreSQL and an isolated ClamAV container.
- Keep authenticated application UI, API and public link resolution on separate
  `wirecopy.app` hosts with host-only application cookies.

## Consequences

### Positive

- One application owns authorization and lifecycle invariants.
- Hotwire avoids an additional frontend runtime and API-for-UI layer.
- PostgreSQL-backed jobs avoid Redis until measured requirements justify it.
- The same application can deliver web UI, JSON API, link resolution and admin
  workflows with one deployment process.

### Negative

- A single initial VM couples application, jobs and database failure domains.
- Rails link resolution must remain efficient under unauthenticated traffic.
- Clerk and Dodo introduce external identity and billing dependencies.
- Operating PostgreSQL and ClamAV on the same host requires explicit resource
  limits, backups and a separation plan as load grows.

## Revisit when

- measured link-resolution load needs an edge cache or dedicated resolver;
- the database or worker workload needs separate hosts;
- Redis-backed behavior is required and cannot be met safely with PostgreSQL;
- identity or billing provider reliability/economics no longer fit;
- data residency evidence determines a different topology.
