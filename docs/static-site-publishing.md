# Static-site publishing exploration

## Product hypothesis

The next product evolution to explore is instant web publishing: select one HTML
file or a folder containing HTML, publish it, and receive a URL where the result
is immediately rendered as a website.

This is not part of the initial file-link release. It is a separate publishing
mode because HTML executes active code, folders introduce routing semantics and
site updates need atomic deployment rather than one-object link delivery.

## Recommended exploration order

Start with managed storage and routing, then generalize the proven contract to
bring-your-own infrastructure.

1. **Managed R2 prototype:** Wirecopy owns the bucket layout, wildcard host,
   router, cache behavior, lifecycle and abuse response.
2. **BYOS storage with Wirecopy routing:** the user owns an S3-compatible bucket
   while Wirecopy optionally supplies the manifest and public hostname control
   plane. This needs an explicit privacy and pricing decision.
3. **Fully user-owned publishing:** upload to a public bucket or the user's own
   router/domain and return its URL. Capabilities vary by provider and must be
   shown honestly.

The first step is recommended because domain provisioning, index routing,
atomic activation, cache invalidation and deletion can be tested as one known
system. It does not make managed storage the permanent or only site mode.

## Proposed managed mechanics

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

Each deployment uploads into a new immutable prefix. The router serves only the
active verified manifest. Switching the active manifest is atomic, so visitors
never see a half-uploaded folder. Previous prefixes have bounded rollback
retention and are later purged.

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

The prototype should compare an R2-backed Worker/router with Cloudflare Workers
Static Assets. Direct public R2 object URLs alone do not define index, SPA,
redirect or atomic-deployment behavior.

## Mandatory origin isolation

User HTML can run arbitrary JavaScript. It must not be served from
`wirecopy.app`, any hostname that can receive Wirecopy cookies, or the ordinary
managed file-link origin. A separate registrable domain is the recommended
security boundary; selecting and registering it is an open decision that
supersedes the current one-domain assumption only if this experiment proceeds.

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

## BYOS mechanics to investigate

The S3 API does not guarantee a website endpoint or common routing behavior.
Provider capability discovery must distinguish:

- private bucket plus temporary object URLs;
- public object base URL without index routing;
- provider website endpoint with index/404 behavior;
- custom domain and TLS ownership;
- cache purge and atomic version switching;
- delete/revoke support.

The app may publish a manifest and objects to any compatible bucket, but it must
not promise a working website unless a reachable public origin and routing mode
are verified. A managed router in front of user-owned storage is a distinct
hybrid service, not pure BYOS, and would require scoped read access or signed
origin requests.

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

## Decisions required after the prototype

- dedicated registrable domain and per-site hostname scheme;
- Rails/R2 router versus Workers Static Assets;
- static multi-page only versus optional SPA fallback;
- file-count, byte, retention and deployment-history limits;
- public-only sites versus controlled/private preview links;
- custom domains and domain-verification workflow;
- acceptable-use, scanning, phishing detection and takedown policy;
- whether managed routing for BYOS is free, paid or unsupported;
- analytics boundaries for site traffic;
- cache purge and rollback guarantees.
