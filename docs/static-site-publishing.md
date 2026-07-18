# Static-site publishing

> Implementation status (2026-07-18): built and governed; production
> enablement flips at operator cutover. Publishing accepts one HTML file, a
> ZIP, or a browser-selected folder; validates and streams assets to an
> immutable storage prefix; and activates a manifest descriptor. Serving is now
> **Rails behind a Cloudflare zone on the resolved artifact domain
> `wirecopy.site`** — not the disposable `s-<token>.wirecopy.app` Worker this
> document explored — with serve-time SHA-256 verification and a batched CDN
> purge as the revocation choke point. Governed bring-your-own-storage
> publishes a Pro user's site into their own bucket while Wirecopy serves,
> verifies, and revokes it through the same edge. The design questions this
> exploration left open are settled in
> [decision 0014](decisions/0014-governed-byos-site-delivery.md), which amends
> [0009](decisions/0009-managed-static-site-mode.md). The production gate
> `SITE_PUBLISHING_ENABLED` is still `false` in `config/deploy.yml` until
> cutover.

## Product hypothesis

The next product evolution to explore is instant web publishing: select one HTML
file or a folder containing HTML, publish it, and receive a URL where the result
is immediately rendered as a website.

This is a separate publishing
mode because HTML executes active code, folders introduce routing semantics and
site updates need atomic deployment rather than one-object link delivery.

The mode is always explicit. An uploaded `.html` remains an ordinary file link
unless the request selects `site`; extension-based auto-preview is prohibited.
The bundled CLI exposes that choice as `wirecopy site <html|zip|folder>` and
packages folders without changing the menu-bar shortcut's file-link behavior.

## Recommended exploration order

Start with managed storage and routing, then generalize the proven contract to
bring-your-own infrastructure.

1. **Managed R2 prototype:** Wirecopy owns the bucket layout, wildcard host,
   router, cache behavior, lifecycle and abuse response.
2. **BYOS storage with Wirecopy routing:** the user owns an S3-compatible bucket
   while Wirecopy supplies the manifest and public hostname control plane. This
   is now the shipped governed-BYOS model (Pro-only), resolved in [decision
   0014](decisions/0014-governed-byos-site-delivery.md); residency and CDN
   visitor-IP disclosures live in the legal drafts.
3. **Fully user-owned publishing:** upload to a public bucket or the user's own
   router/domain and return its URL. Capabilities vary by provider and must be
   shown honestly.

The first step is recommended because domain provisioning, index routing,
atomic activation, cache invalidation and deletion can be tested as one known
system. It does not make managed storage the permanent or only site mode.

## Managed mechanics

### Prepare

- A single `.html` file is normalized to `index.html` unless the user chooses an
  explicit path.
- A folder is traversed without following symlinks, aliases, packages or hidden
  parent paths.
- Paths are normalized to safe relative URL paths. Reject traversal, absolute
  paths, case collisions and ambiguous Unicode normalization.
- Produce a manifest containing path, size, MIME type and checksum for every
  asset.
- Require a root `index.html` for the first prototype. SPA fallback, custom 404
  pages and redirect rules are later routing modes.

### Upload and activate

```text
Mac client          Rails API             Private R2          Site router
    │                   │                     │                    │
    │─ create deploy ──▶│                     │                    │
    │◀─ scoped grants ──│                     │                    │
    │──────────── direct versioned uploads ──▶│                    │
    │─ complete manifest▶                     │                    │
    │                   │─ verify + scan ─────▶│                    │
    │                   │─ atomically activate manifest ──────────▶│
    │◀─ public site URL ─│                     │                    │
```

Each deployment uploads into a new immutable prefix. Publishing writes the
activation descriptor under `wirecopy-sites/index/<token>.json` only after all
manifest assets are stored. The router serves only the active verified
manifest. Switching the active manifest is atomic, so visitors never see a
half-uploaded folder. Previous prefixes have bounded rollback retention and are
later purged.

In production the "Site router" column above is now **Rails serving on
`wirecopy.site`**, behind a Cloudflare zone and a Caddy accessory, not the
separate Cloudflare Worker this document originally sketched. See [decision
0014](decisions/0014-governed-byos-site-delivery.md).

The client needs batched grants and bounded concurrency; one API round trip per
tiny asset would perform poorly. Completion verifies the manifest against R2
metadata before activation. Cache keys include the immutable deployment prefix,
while the HTML entry point receives short caching and explicit purge behavior.

### Route

Use a dedicated site hostname per published site so service workers, browser
storage and same-origin privileges are isolated between users. The router maps:

- `/` to `/index.html`;
- exact normalized paths to manifest objects;
- directory paths to `index.html` only when that behavior is explicitly enabled;
- missing assets to a deterministic 404.

That comparison is now resolved ([decision
0014](decisions/0014-governed-byos-site-delivery.md)): production serves from
Rails, not a Worker or Workers Static Assets. A host-constraint route maps each
`s-<32hex>.wirecopy.site` subdomain to `PublishedSitesController#show`, which
reads the Postgres-authoritative manifest and streams SHA-256-verified bytes.
Direct public R2 object URLs alone do not define index, SPA, redirect or
atomic-deployment behavior.

## Mandatory origin isolation

User HTML can run arbitrary JavaScript. It must not be served from
`wirecopy.app`, any hostname that can receive Wirecopy cookies, or the ordinary
managed file-link origin. A separate registrable domain is the required
production security boundary; it is now resolved and registered as
`wirecopy.site` ([decision
0014](decisions/0014-governed-byos-site-delivery.md)). Cloudflare terminates
its TLS and caches; a Caddy accessory presents a Cloudflare Origin CA wildcard
certificate and reverse-proxies to Rails, which owns host-token routing and
serve-time verification.

The site origin receives:

- no application cookies, authorization headers or managed bearer tokens;
- no access to account/API CORS endpoints;
- isolated per-site hostnames to contain cookies, local storage and service
  workers;
- explicit MIME types, `nosniff`, referrer and cache policies;
- abuse reporting, takedown and lifecycle enforcement.

ClamAV is not a malicious-JavaScript detector. The product is intentionally
hosting owner-supplied active content, so acceptable-use, phishing detection,
rate limits, domain reputation and rapid takedown are core prototype gates.

## BYOS boundary (governed)

The earlier boundary — a BYOS publication stays an ordinary download link
unless the user configures their own public website endpoint, and Wirecopy
never lends its hostname to a user-owned backend — is superseded by [decision
0014](decisions/0014-governed-byos-site-delivery.md). Governed BYOS inverts it:
a Pro user connects one S3-compatible bucket in the web dashboard, publishes
flow through the managed API into that bucket, and **Wirecopy serves, verifies,
revokes, and purges the site through the `wirecopy.site` artifact domain**
exactly as it does for managed sites. The customer never needs a provider
website endpoint, index routing, or TLS of their own, because none of the
S3-API website gaps are on the serving path anymore — Rails is.

What still matters for a connected bucket is narrower: credentials (an
https-only endpoint, stored with non-deterministic Active Record encryption), a
write / read-back / delete probe before the connection is marked usable, and
delete support so retirement can empty it. Serve-time SHA-256 verification
treats a customer bucket as untrusted storage: tampered bytes fail to a 404
(small objects) or truncate the response (large objects), the same as managed
R2. BYOS is Pro-only and operator-granted until billing ships; its bytes are
not counted against managed quota, though per-publish size and file-count
limits still apply.

## Prototype scope

The smallest useful experiment supports:

- one HTML file or one folder with a root `index.html`;
- HTML, CSS, JavaScript, JSON, images and fonts within an allowlisted matrix;
- a bounded file count, total bytes and maximum individual asset size;
- one generated per-site hostname;
- publish, atomic replace, open and delete;
- deterministic 404 behavior;
- no server-side code, build step, custom domain or SPA fallback.

## Automated validation

Extend the [testing harness](testing-harness.md) with generated site fixtures:

- single HTML, nested assets and relative links;
- missing index, broken references and MIME mismatches;
- traversal, symlink, case-collision and Unicode-path attacks;
- HTML/JavaScript execution on the isolated origin;
- cookie, CORS, browser-storage and service-worker isolation between sites;
- interrupted upload proving that partial deployments are unreachable;
- atomic replacement under concurrent traffic;
- cache refresh, rollback, delete and takedown behavior;
- equivalent manifest publication to MinIO and each supported BYOS provider.

Browser automation should load the deployed URL and assert real asset/routing
behavior. A successful series of S3 PUTs is not enough.

## Decisions resolved after the prototype

[Decision 0014](decisions/0014-governed-byos-site-delivery.md) settles the
questions this exploration opened:

- **Domain and hostname scheme** — `s-<32hex>.wirecopy.site`, a separate
  registrable artifact domain, orange-clouded through Cloudflare.
- **Router** — Rails serves (host-constraint route →
  `PublishedSitesController#show`), not a Worker or Workers Static Assets.
- **Acceptable-use, scanning, phishing, takedown** — a public `/abuse` intake,
  console takedown via `Sites::Retire`, CDN purge, and ClamAV scanning at
  publish when the scanner is enabled.
- **Managed routing for BYOS** — supplied and governed, Pro-only; the "free,
  paid or unsupported" question resolved to "governed for Pro".
- **Cache purge and revocation** — a batched, rate-aware Cloudflare
  purge-by-URL job is the revocation choke point; the CDN entry TTL bounds the
  staleness window.

Still open (tracked in 0014's "Revisit when"): SPA fallback and custom 404
pages, custom domains and their verification workflow, controlled/private
preview links, per-site analytics boundaries, managed-site byte accounting, and
atomic rollback guarantees.
