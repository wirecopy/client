# 0005: Use PostgreSQL and MinIO for local service development

- Status: Accepted for implementation
- Date: 2026-07-16

## Context

Local development must exercise the production database adapter and an
S3-compatible direct-upload flow without requiring cloud credentials. Running a
large container stack would increase memory use and setup time, while SQLite
would create a second database behavior that production never uses.

## Decision

Use one small Docker Compose file with exactly two default services:

- `db`: a pinned PostgreSQL image, separate development/test databases, a
  health check and a persistent named volume;
- `minio`: a pinned MinIO image, a private development bucket, a health check
  and a persistent named volume.

Rails runs on the host. Both services bind only to `127.0.0.1` and use clearly
development-only credentials from `.env.example`. `bin/setup` waits for health,
creates/migrates databases and idempotently creates the MinIO bucket using the
application S3 client.

No SQLite adapter, locally installed PostgreSQL, Rails application container,
Redis or mail service belongs in the default setup. Ordinary tests use a scanner
fake; real ClamAV coverage runs through an explicit optional profile or CI job.
Deployed environments must reject scan bypass and development credentials.

## Consequences

### Positive

- Development matches PostgreSQL semantics used in production.
- MinIO exercises scoped PUT, object verification and signed GET behavior
  without external infrastructure.
- Rails reloads quickly on the host and the default container footprint stays
  small.
- One setup path reduces adapter-specific branches and documentation.

### Negative

- Docker is required for managed-service development.
- MinIO compatibility does not prove exact R2 behavior, so real R2 contract
  tests remain necessary.
- Most local test runs do not exercise the real scanning engine.

## Revisit when

- the service requires another production dependency that cannot be represented
  by a test double;
- containerizing Rails materially improves contributor consistency;
- MinIO behavior diverges enough from R2 to make it misleading;
- scanner integration becomes fast and light enough for every local run.
