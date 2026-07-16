# Repository instructions for coding agents

These instructions apply to the entire repository.

## Start here

1. Read `README.md` for the current product position.
2. Read `docs/product-thesis.md` and `docs/competitive-landscape.md` before
   proposing scope or positioning changes.
3. Read the relevant focused document before editing it.
4. Check `git status --short` and preserve unrelated user changes.

## Product boundaries

- Wirecopy is the selected product name (see
  `docs/decisions/0003-wirecopy-product-name.md`). Do not describe the product
  as launched until the domain, trademark and release gates are complete.
- Do not describe the product as merely an S3 uploader or screenshot tool.
- The core job is clipboard-to-controlled-link publishing for developers.
- Managed cloud and bring-your-own S3 must present one consistent workflow.
- The default path should remain copy, shortcut, link, paste.
- Do not claim support for “any file” until compatibility tests prove it.
- Do not imply client-side encryption exists until its protocol and recovery
  behavior are implemented and reviewed.

## Research standards

- Prefer primary sources: vendor documentation, pricing pages and platform
  documentation.
- Add the observation date for time-sensitive pricing, limits or features.
- Separate verified facts from product hypotheses and recommendations.
- Link directly to the page supporting each competitive claim.
- Do not copy competitor marketing text; summarize it.
- Recheck current sources before publishing comparisons externally.

## Documentation structure

Keep `README.md` concise. Put detailed material in the focused documents under
`docs/` and link it from the research map.

- Product and audience: `docs/product-thesis.md`
- Competitors: `docs/competitive-landscape.md`
- Product wedge and roadmap: `docs/differentiation.md`
- Native Mac interaction: `docs/macos-experience.md`
- Technical system design: `docs/architecture.md`
- Hosted service: `docs/managed-cloud.md`
- Security and abuse: `docs/security-and-abuse.md`
- Pricing and economics: `docs/business-model.md`
- Evidence and experiments: `docs/validation-plan.md`
- Source inventory: `docs/research-sources.md`
- Accepted decisions: `docs/decisions/`

## Future implementation rules

- Prefer a native Swift and SwiftUI application with AppKit where macOS APIs
  require it.
- Keep the Apache-2.0 Mac app, standalone CLI, shared Swift model, BYOS adapters
  and managed OpenAPI contract in the public client repository. Keep the Rails
  managed-service implementation and operations in a private repository.
- Pin the private service to an exact public contract tag or commit and verify
  compatibility in CI; never build against an unpinned `latest` contract.
- Keep clipboard inspection, publishing, storage destinations and output
  formatting behind separate interfaces.
- Store user-owned credentials in Keychain, never plaintext preferences.
- Managed uploads should go directly from the client to object storage using a
  narrowly scoped upload grant; do not proxy file bytes through the API.
- Serve untrusted content from a domain that cannot receive application cookies.
- Treat expiration, revocation, deletion, rate limits and abuse reporting as
  core behavior rather than post-launch additions.
- Add no client diagnostics without an explicit data inventory and settings
  opt-in. Keep filenames, URLs, clipboard contents, object keys and credentials
  out of telemetry.
- Build the managed service as a Rails 8.1 Hotwire monolith using PostgreSQL and
  Solid Queue. Do not add a separate frontend or Redis without demonstrated
  need.
- For local service work, run Rails on the host and keep the default Docker
  Compose file to PostgreSQL and MinIO. Do not add SQLite as a second adapter.
- Production uses private Cloudflare R2 object storage and an initial Kamal
  deployment on Hetzner. Missing production database, storage or scanner
  configuration must fail closed.
- Bundle the standalone `wirecopy` CLI in the signed application Homebrew Cask;
  do not introduce a separate formula until independent installation is needed.
- Keep `./scripts/verify` non-interactive in both repositories. It must create
  disposable test environments, reject production targets, emit machine-readable
  evidence and cover the scenario matrix in `docs/testing-harness.md`.
- Treat rendered HTML/folder publishing as the separate exploration in
  `docs/static-site-publishing.md`, not as initial file support. Never serve
  user HTML from `wirecopy.app` or the ordinary managed-link origin.

## Validation

For documentation changes, run:

```bash
npx --yes markdownlint-cli2 "**/*.md"
git diff --check
```

Run `markdown-link-check` on each edited Markdown file. External rate limits
must be investigated separately from broken links.

When code is introduced, document its build, test, signing and notarization
commands here before considering the implementation complete.

## Git workflow

Make small, self-contained commits. Do not publish, release, change repository
visibility or create external infrastructure unless the user explicitly asks.
