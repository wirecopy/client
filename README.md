# Wirecopy

> Product name selected in
> [decision 0003](docs/decisions/0003-wirecopy-product-name.md). Public launch
> remains gated on domain registration, trademark review and a signed release.

Wirecopy is a product research repository for a developer-focused
macOS utility that turns copied images and files into controlled share links.

The intended default workflow is deliberately small:

```text
Copy an image or file
        ↓
Press one global shortcut
        ↓
Publish through managed cloud or user-owned S3
        ↓
Replace the clipboard with a link
        ↓
Paste anywhere
```

The current thesis is not “another screenshot uploader.” It is a programmable
publishing primitive for terminals, coding agents, GitHub, Markdown, chat,
email, Finder, Shortcuts, Raycast and any application that accepts a URL.

## Current position

- Managed cloud provides a zero-configuration default.
- Bring-your-own S3 provides ownership, portability and custom infrastructure.
- The normal path has no shelf, modal or file picker.
- Privacy, expiration and revocation are product defaults.
- The Mac app, CLI, API and integrations share one publishing model.

Competition is strong. A generic “upload and copy link” utility is not enough.
The project should proceed only if it can be materially faster, more private
and more programmable than established Mac sharing tools.

## Research map

| Document | Purpose |
| --- | --- |
| [Product thesis](docs/product-thesis.md) | Defines the user, problem, positioning and boundaries. |
| [Competitive landscape](docs/competitive-landscape.md) | Maps direct and adjacent competitors and the market implications. |
| [Differentiation](docs/differentiation.md) | Identifies the wedge and features that could make the product stand out. |
| [macOS experience](docs/macos-experience.md) | Specifies clipboard, hotkey, Finder, Share menu and file behavior. |
| [Architecture](docs/architecture.md) | Describes the native client, managed backend, uploads and links. |
| [Managed cloud](docs/managed-cloud.md) | Defines hosted storage, lifecycle, quotas and operating model. |
| [Security and abuse](docs/security-and-abuse.md) | Covers trust boundaries and public-hosting responsibilities. |
| [Business model](docs/business-model.md) | Captures pricing hypotheses and sustainable usage metrics. |
| [Validation plan](docs/validation-plan.md) | Defines tests that must pass before building the full SaaS. |
| [Automated testing harness](docs/testing-harness.md) | Defines non-interactive environments, simulators and release evidence. |
| [Static-site publishing](docs/static-site-publishing.md) | Explores instant HTML/folder publishing through managed R2 and BYOS. |
| [Research sources](docs/research-sources.md) | Records primary sources and time-sensitive observations. |
| [Decisions](docs/decisions/README.md) | Preserves accepted product and architecture decisions. |

## Status

The native Swift menu-bar application and standalone CLI are implemented under
[`macos/`](macos/). The Rails managed service is implemented in the sibling
`service/` repository. Local integration uses PostgreSQL and MinIO, and the
versioned boundary is [`contracts/managed-api-v1.yaml`](contracts/managed-api-v1.yaml).

See the [macOS development guide](macos/README.md) for building, configuring,
testing and installing the native app locally.

## Next product exploration

Explore instant static-site publishing: select one HTML file or a folder with a
root `index.html`, publish it, and receive a URL where the site is immediately
live. Start with managed R2 storage and controlled routing because one known
cloud environment makes domains, atomic activation, cache behavior and deletion
testable. Then evaluate BYOS storage with either Wirecopy-managed routing or a
fully user-owned website endpoint.

This is an exploration, not an initial-release promise. Serving HTML means
hosting active JavaScript, so it requires a dedicated cookie-isolated site
domain, per-site origin isolation, atomic folder deployments and stronger abuse
controls. See [Static-site publishing exploration](docs/static-site-publishing.md).
