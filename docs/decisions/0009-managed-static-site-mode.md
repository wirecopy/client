# 0009: Separate managed static-site publishing from file links

- Status: Accepted and implemented as a local/live tracer
- Date: 2026-07-17
- Amended by: [0014](0014-governed-byos-site-delivery.md), which supersedes the
  Cloudflare Worker serving topology below and the "BYOS receives no managed
  preview URL" stance. The explicit `file`/`site` mode split and the
  separate-registrable-domain requirement still hold.

## Context

An HTML document can be either a file someone intends to download or executable
web content someone intends to visit. Inferring intent from the extension would
make ordinary uploads unexpectedly executable. Static folders also require path
validation, MIME routing, atomic activation and a stronger origin boundary than
one-object download links.

Managed Cloudflare R2 can be paired with a Wirecopy-owned router and hostname.
User-owned storage has provider-specific website, domain and routing behavior;
OpenDAL normalizes object operations but does not create those public-site
capabilities.

## Decision

Every publication has an explicit mode:

- `file` is the default, including for `.html`; it produces an ordinary
  controlled download link;
- `site` is an explicit action for one HTML file, a ZIP, or a selected folder
  containing a root `index.html`.

Managed `site` mode writes validated assets under an immutable R2 prefix and
activates them by writing one manifest descriptor last. A Cloudflare Worker
serves only paths listed by that descriptor at an
`s-<token>.<artifact-domain>` hostname. The artifact domain must be a separate
registrable domain from `wirecopy.app`, must never receive app/API cookies, and
must not be an allowed app/API CORS origin. Per-site hostnames isolate local
storage and service-worker scope. The artifact domain itself remains an
untrusted active-content boundary.

The 2026-07-17 R2 tracer temporarily used `s-<token>.wirecopy.app` to prove
wildcard routing, MIME handling and cleanup. Its fixtures were removed after
the run. That tracer route is not an accepted production origin and does not
supersede the separate-registrable-domain requirement.

Managed R2 continues to use its S3-compatible SDK path. OpenDAL is the
capability-aware BYOS adapter for server-side object operations. BYOS does not
receive a Wirecopy preview URL by default; the owner is responsible for public
bucket, website endpoint, domain and routing configuration. A future
destination-specific adapter may advertise a verified `public_site`
capability.

The native Swift app does not embed the Ruby binding. Native destinations and
OpenDAL-backed service adapters implement the same conceptual capability model.

## Consequences

- HTML never becomes executable because of its filename alone.
- Managed sites can offer one reliable URL and lifecycle while BYOS claims stay
  honest.
- The managed service owns public-content abuse, phishing and takedown work.
- Production cannot enable `site` mode until a dedicated artifact domain is
  selected, delegated and covered by the router.
- Static publication is a distinct quota and security surface even when its UI
  shares Wirecopy's publishing vocabulary.
- OpenDAL's Ruby binding is synchronous and currently does not expose the
  presign operation used by direct browser uploads. Its 0.1.7 release candidate
  also failed to build from the generic gem on macOS 26 because the packaged
  source omitted the Cargo lockfile while invoking `--locked` (observed
  2026-07-17). It remains optional until a compatible release is available.

## Revisit when

- the OpenDAL Ruby binding exposes stable presigning and compatible release
  packages;
- a BYOS provider adapter can prove a public-site origin and routing behavior;
- managed site traffic requires moving manifest activation or routing away
  from the initial Worker/R2 topology;
- custom domains, private previews or atomic rollback are prioritized.
