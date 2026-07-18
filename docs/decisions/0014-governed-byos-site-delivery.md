# 0014: Govern site delivery on a separate domain and open BYOS through it

- Status: Accepted and implemented; production enablement flips at operator
  cutover
- Date: 2026-07-18
- Amends: [0009](0009-managed-static-site-mode.md) — supersedes its Cloudflare
  Worker serving topology and its "BYOS receives no managed URL" stance.

## Context

Decision 0009 established static-site publishing as an explicit `site` mode,
separate from file links, and proved the mechanics with a disposable
Cloudflare Worker on `s-<token>.wirecopy.app`. It left two things open: a
production serving topology on a properly separated domain, and whether
bring-your-own-storage sites could ever get a Wirecopy-served URL.

Two forces closed those questions. First, Cloudflare Drop (July 2026)
commoditized instant static preview, so the defensible product is not "publish
fast" but "publish under control" — links that expire, revoke, verify their
own bytes, and can be taken down. Second, that control only has value if
Wirecopy owns the serving edge, which the earlier "BYOS is on its own" stance
gave away: a user's own bucket website endpoint offers no expiry, revocation,
serve-time verification, or takedown.

The verified constraints shaped the topology. kamal-proxy cannot match
wildcard hosts and cannot issue a Let's Encrypt wildcard without DNS-01, so it
cannot terminate `*.<artifact-domain>` TLS itself. Cloudflare purge-by-URL on
the free plan is rate-limited (30 URLs per request, roughly 25 per bucket
refilling about 5 per minute), so revocation has to be a batched, rate-aware
job rather than a synchronous call. Active Record encryption was not yet
configured, which BYOS credentials require.

## Decision

Site delivery is governed by Wirecopy on a **separate registrable artifact
domain** (`wirecopy.site`, env-driven `SITE_PUBLIC_DOMAIN`, never
`wirecopy.app`), and the same governed edge serves both managed and BYOS
sites.

**Serving topology.** The Cloudflare Worker is replaced by Rails behind a
Cloudflare zone. A browser reaches `https://s-<32hex>.<artifact-domain>`;
Cloudflare terminates public TLS and caches; a Cloudflare Origin Rule rewrites
the public 443 to origin 8443; a dedicated Caddy accessory (`site-edge`,
`caddy:2.10-alpine`) on the VPS presents a Cloudflare Origin CA wildcard
certificate and reverse-proxies to the Rails container over the shared Kamal
network (`wirecopy-rails:80`), forwarding `CF-Connecting-IP` as
`X-Forwarded-For`. Rails owns routing and verification: a host constraint
matches `s-<32hex>.<artifact-domain>`, parses the token from `request.host`,
and serves through `PublishedSitesController#show`. Host governance is the
routing constraint plus a Postgres token lookup — an unknown or spoofed host
resolves to a bare 404. The manifest is read from Postgres (authoritative);
storage is resolved per site. Caddy stays deliberately dumb (no path
rewriting, no compression, Host passed through), so subdomain serving also
works in development with `SITE_PUBLIC_DOMAIN=localhost` and no Caddy at all.
The `8443` port must be firewalled to Cloudflare IP ranges — that firewall is
what makes the forwarded visitor address trustworthy and is a hard bring-up
prerequisite.

**Serve-time verification for every site.** Before or during delivery, Rails
recomputes the SHA-256 and byte size of each object against the manifest.
Objects at or under 256 KB are buffered and fully verified before any bytes
are sent, so a mismatch becomes a clean 404. Larger objects stream while the
digest is verified and a mismatch at the end truncates the response rather
than delivering swapped bytes. This covers tampering in a customer bucket the
same way it covers managed storage.

**Governed BYOS.** Pro users connect one S3-compatible bucket in the web
dashboard; publishes flow through the managed API, which writes to the
customer bucket, and Wirecopy serves, verifies, revokes, and purges through
the artifact domain exactly as it does for managed sites. Destination is
explicit per publish (`site[storage]=managed|byos`, default `managed`; CLI
`--storage`), shown in the dashboard only when a usable connection exists.
BYOS is Pro-only (`user.plan == "pro"`), operator-granted by console until
Dodo billing ships, and enforced both at connection creation and at publish.
BYOS credentials are stored with non-deterministic Active Record encryption;
BYOS bytes are not counted against managed storage quota, but per-publish size
and file-count limits still apply.

**Revocation and lifecycle through one choke point.** `Sites::Retire`
computes the site's cache URLs, deletes the descriptor and object tree with
the per-site client, marks `storage_purged_at`, and enqueues a batched,
rate-aware Cloudflare purge-by-URL job. Reasons are `:deleted`, `:expired`
(keeps the row `published` as a historical record, only purges storage),
`:takedown`, and `:account_deleted`. Account deletion retires every un-purged
site — managed and BYOS — before destroying the user. Between revocation and
purge, the CDN may still serve cached content, bounded by a short (60s) entry
TTL.

**Public-content abuse kit.** A public `/abuse` report page (unauthenticated,
honeypot-guarded, rate-limited), console takedown via
`Sites::Retire.call(site, reason: :takedown)`, CDN purge, and ClamAV scanning
of site files at publish when the scanner is enabled make the surface
governable enough to open to the public.

The production feature gate (`SITE_PUBLISHING_ENABLED`) stays `false` in
`config/deploy.yml` until the operator flips it at cutover, once the artifact
domain, Caddy accessory, firewall, scoped purge token, and zone id are live
and smoke-verified. The Worker is retired only after cutover passes; until
then `workers/site-router/` stays in place as a rollback reference and is not
an approved production origin.

## Consequences

- Managed and BYOS sites share one governed serving, verification, revocation,
  and takedown path; "their storage, our control plane" is now real rather
  than a boundary disclaimer.
- Swapped or corrupted bytes in any bucket — including a customer's — cannot
  be served: small objects fail to a 404, large ones truncate.
- Revocation is eventually consistent to the edge, not instant. The short
  entry TTL bounds the window and the purge job closes it; a mass-takedown
  storm degrades gracefully to TTL expiry rather than failing.
- BYOS depends on the customer's bucket. An outage or revoked credential
  surfaces as a 503 with a throttled connection health mark, and further
  publishing is blocked until an explicit re-probe.
- Trust isolation holds: artifact JavaScript runs only on a separate
  registrable domain that never receives Wirecopy cookies and is not an
  app/API CORS origin.
- New operational surface: an Origin CA certificate to rotate, a firewall rule
  that must not lapse, a scoped purge token, and Active Record encryption keys
  in credentials. These are documented in the operations runbook.
- The Cloudflare zone and Caddy accessory couple site delivery to the single
  VPS and to Cloudflare; accepted pre-launch.

## Alternatives considered

- **Keep the Cloudflare Worker on a separate zone.** Rejected because serving
  from Rails is what makes serve-time SHA-256 verification, Postgres-authoritative
  manifests, and a single retire/purge choke point possible without duplicating
  lifecycle logic at the edge; the Worker would still need the manifest and the
  same verification.
- **Leave BYOS ungoverned (0009's stance).** Rejected because an unmanaged
  bucket website endpoint offers none of the controls that are now the product,
  so a BYOS "site" would be a second-class download link, not a governed site.
- **kamal-proxy terminating wildcard TLS.** Not possible: no wildcard host
  matching and no DNS-01 for a Let's Encrypt wildcard. The Caddy accessory plus
  Cloudflare Origin CA cert is the working path.
- **A second VPS IP with Caddy on 443** (0009-era fallback). Not needed: the
  Cloudflare Origin Rule port rewrite is available on the free plan, verified at
  bring-up.

## Revisit when

- managed-site byte accounting lands and BYOS quota treatment is reconsidered;
- more than one storage connection per user is exposed (the schema is already
  multi-ready);
- purge volume outgrows the free-plan rate budget, or a paid Cloudflare tier
  changes the batching math;
- custom domains, private previews, or atomic rollback are prioritized;
- the single-VPS / single-zone coupling needs to become redundant.
