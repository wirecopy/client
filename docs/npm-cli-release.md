# npm CLI release

This checklist governs public releases of the `wirecopy` npm package. It is a
release gate, not a retrospective.

## Ownership and source

- The npm package name `wirecopy` is controlled by the Wirecopy maintainer
  account with two-factor authentication required for writes.
- The source repository is public and its default branch is protected.
- A full-history secret scan reports no findings before the repository first
  becomes public.
- `package.json` points to the exact public source directory and declares the
  Apache-2.0 license.
- Only `dist/`, `README.md` and `LICENSE` appear in `npm pack --dry-run`.

## Build and supply chain

- CI runs `npm ci`, tests and package inspection on macOS, Linux and Windows
  with the oldest and newest supported Node.js lines.
- The package contains no runtime dependencies.
- npm Trusted Publishing is restricted to
  `.github/workflows/publish-cli.yml` in `wirecopy/client`.
- The GitHub `npm` environment protects the publishing job.
- Release tags use `cli-v<package-version>` and the workflow rejects a tag that
  does not match `package.json`.
- npm provenance is present on every automated release.
- Maintainers publish only through the release workflow after the initial
  package reservation; no long-lived write token is stored in GitHub.

## Client safeguards

- Device tokens are never printed, logged or included in errors.
- Interactive configuration does not echo tokens or place them in shell
  history.
- Stored configuration uses mode `0600` where the platform supports POSIX
  permissions; CI uses `WIRECOPY_TOKEN`.
- Remote API and upload URLs require HTTPS. Plaintext HTTP is allowed only on
  loopback for local development.
- API and upload redirects are refused so bearer credentials and signed grant
  URLs cannot move to an unexpected origin.
- API requests, direct uploads and site publications have explicit timeouts.
- Ordinary files use the scoped direct-upload grant. The device token is never
  sent to object storage.
- Site folders reject symbolic links and unsafe paths, require a root
  `index.html`, exclude hidden files and produce a deterministic ZIP locally.
- Temporary archives and multipart request files are deleted after success or
  failure.
- Progress is written to stderr; URLs and JSON are written to stdout.

## Service preflight

- `https://wirecopy.app/up` returns `200`.
- An unauthenticated API request returns the structured `unauthorized` envelope.
- Upload-intent, site-publication and public-resolution rate limits are active.
- Authorization headers and parameters matching `token` remain filtered from
  Rails logs.
- Free and Pro size, daily-send, storage and retention boundaries have passing
  tests.
- A revoked device token immediately loses API access.
- A direct upload is unavailable until object verification and malware scanning
  complete.
- Site publishing is advertised only while `SITE_PUBLISHING_ENABLED=true`.

The artifact preflight must use a product-shaped wildcard hostname, not the
unused `wirecopy.site` apex:

```bash
curl -sS -D - -o /dev/null \
  https://s-ffffffffffffffffffffffffffffffff.wirecopy.site/
```

An unknown token must return `404` through Cloudflare and Caddy with no
`Set-Cookie`. The apex may have different TLS behavior because it is not a
published-site origin.

Before every production release, run the live-site smoke harness against a
disposable site. It must verify HTML, CSS and JavaScript delivery, MIME types,
per-site origin isolation, cache purge, revocation and cleanup.

## Rollout

1. Publish a prerelease under the `next` dist-tag.
2. Install from the registry on clean macOS, Linux and Windows environments.
3. Exercise file publish, site publish, JSON output, link listing and revoke
   against a disposable production account.
4. Inspect npm provenance, tarball contents and the linked source revision.
5. Promote the tested version to `latest`.
6. Watch API error codes, rate limits, scan failures and site-origin `5xx`
   responses without logging filenames, links or credentials.

## Rollback and incident response

- Deprecate a bad package version with an actionable message; do not silently
  replace immutable package bytes.
- Move `latest` back to the last known-good version.
- Revoke the npm trusted-publisher relationship and GitHub environment access
  if the release path is compromised.
- Revoke affected device tokens from the web dashboard.
- Disable site serving with `SITE_PUBLISHING_ENABLED=false` if the artifact
  boundary fails; file publishing can remain available independently.
- Preserve the package, workflow, source commit and redacted service request IDs
  needed for incident analysis.
