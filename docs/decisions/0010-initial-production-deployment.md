# 0010: Use Kamal and GHCR for the initial production deployment

- Status: Accepted for initial production bring-up
- Date: 2026-07-17

## Context

Wirecopy needs a production environment that can be operated from a developer
machine without introducing a platform team, bespoke CI system or multiple
application runtimes. The first host is a single Hetzner VM. Cloudflare R2 and
Clerk remain managed dependencies outside that host.

The first deployment is a production bring-up, not the paid public beta.
Payment onboarding cannot be completed until the production website exists,
and ClamAV has intentionally been deferred. Static-site publishing also cannot
be enabled safely on `wirecopy.app`; decision 0009 requires a separate
registrable artifact domain.

## Decision

Use the following initial production topology:

- Kamal 2 builds and deploys the Rails container from a developer machine.
- GitHub Container Registry stores the private
  `ghcr.io/wirecopy/service` image.
- A non-root `deploy` SSH user operates Docker on the VM. Root access remains a
  temporary break-glass path until the first deployment and rollback are
  verified.
- Kamal Proxy owns ports 80 and 443, terminates TLS for `wirecopy.app`, and
  replaces healthy Rails containers without application downtime.
- PostgreSQL 17 runs as a persistent Kamal accessory and exposes its port only
  on server loopback.
- Rails and Solid Queue initially run in the same application container.
- Managed object bytes remain in private Cloudflare R2.
- Deployment secrets live only in an ignored local environment file and
  Kamal's ignored secrets bridge. No production credential is committed.

The local `bin/deploy` command is the supported operator entry point. It checks
the required environment, obtains GHCR authentication from GitHub CLI, derives
the internal database URL and delegates to Kamal. A dirty checkout is rejected
so an image always corresponds to a committed revision.

Initial feature gates are explicit:

- `BILLING_ENABLED=false` until Dodo production onboarding is complete.
- `SCANNER_MODE=disabled` requires
  `ALLOW_UNSCANNED_UPLOADS=true`; the product must disclose that uploads are not
  malware-scanned. This exception is limited to controlled production
  bring-up and must not silently become the paid-beta policy from decision
  0006.
- `SITE_PUBLISHING_ENABLED=false` until the isolated artifact origin required
  by decision 0009 exists.

The apex `wirecopy.app` hostname is the application origin; an `app.` hostname
is not introduced. `www` redirects to the apex at the DNS/edge layer. Clerk's
production instance and its prescribed custom-domain records must be healthy
before authentication is considered production-ready.

## Consequences

### Positive

- Deployment, logs, rollback and accessory management use one established tool.
- GHCR stays aligned with the GitHub organization and avoids another registry
  account.
- The application runs as an unprivileged container behind an unprivileged
  deployment account.
- Billing, malware scanning and static-site hosting cannot appear enabled when
  their production dependencies are absent.

### Negative

- A single VM still couples Rails, jobs and PostgreSQL failure domains.
- Local deployment depends on Docker, GitHub CLI credentials, SSH access and
  the operator's ignored production environment file.
- Uploads during controlled bring-up are not malware-scanned.
- The first production image is built on the operator machine rather than by
  an attestable CI release pipeline.

## Revisit when

- the paid beta is opened to untrusted users;
- deployment ownership moves beyond one operator;
- CI-built, signed images or provenance attestations become necessary;
- PostgreSQL or jobs need an independent failure domain;
- the separate artifact domain is selected and static-site publishing can be
  enabled;
- the first deploy and rollback are verified, after which routine root SSH
  access should be disabled.
